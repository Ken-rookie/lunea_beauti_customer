import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "jsr:@supabase/server@^1";

export default {
  fetch: withSupabase({ auth: ["user"] }, async (req, ctx) => {
    if (req.method !== "POST") {
      return Response.json(
        { error: "Use POST to create checkout." },
        { status: 405 },
      );
    }

    try {
      const body = await req.json();
      const orderId = body.order_id;

      if (
        typeof orderId !== "string" ||
        !/^[0-9a-f-]{36}$/i.test(orderId)
      ) {
        return Response.json(
          { error: "A valid order_id is required." },
          { status: 400 },
        );
      }

      // RLS restricts this query to the signed-in customer's orders.
      const { data: order, error: orderError } = await ctx.supabase
        .from("orders")
        .select(
          "id, order_number, customer_name, email, total, payment_method, payment_status",
        )
        .eq("id", orderId)
        .single();

      if (orderError || !order) {
        return Response.json(
          { error: "Order not found or access denied." },
          { status: 404 },
        );
      }

      if (order.payment_status !== "pending") {
        return Response.json(
          { error: "This order is not awaiting payment." },
          { status: 409 },
        );
      }

      const method = String(order.payment_method).toLowerCase();

      if (
        !["paymongo", "gcash", "maya", "paymaya", "credit / debit card",
          "credit/debit card", "card"].includes(method)
      ) {
        return Response.json(
          { error: "This order does not use online payment." },
          { status: 400 },
        );
      }

      const { data: items, error: itemsError } = await ctx.supabase
        .from("order_items")
        .select("product_name, unit_price, quantity")
        .eq("order_id", orderId);

      if (itemsError || !items || items.length === 0) {
        return Response.json(
          { error: "Order items could not be loaded." },
          { status: 400 },
        );
      }

      const total = Number(order.total);
      const itemsTotal = items.reduce(
        (sum, item) =>
          sum + Number(item.unit_price) * Number(item.quantity),
        0,
      );

      if (
        !Number.isFinite(total) ||
        total <= 0 ||
        !Number.isFinite(itemsTotal) ||
        itemsTotal <= 0 ||
        itemsTotal > total + 0.01
      ) {
        return Response.json(
          { error: "Order total could not be validated." },
          { status: 400 },
        );
      }

      const lineItems = items.map((item) => ({
        name: String(item.product_name).slice(0, 120),
        amount: Math.round(Number(item.unit_price) * 100),
        currency: "PHP",
        quantity: Number(item.quantity),
      }));

      const shippingCentavos = Math.round((total - itemsTotal) * 100);

      if (shippingCentavos > 0) {
        lineItems.push({
          name: "Shipping",
          amount: shippingCentavos,
          currency: "PHP",
          quantity: 1,
        });
      }

      const mode = (Deno.env.get("PAYMONGO_MODE") ?? "test")
        .trim()
        .toLowerCase();
      if (mode !== "test" && mode !== "live") {
        return Response.json(
          { error: "PAYMONGO_MODE must be set to test or live." },
          { status: 500 },
        );
      }

      const secretKey = Deno.env.get("PAYMONGO_SECRET_KEY");
      const expectedKeyPrefix = mode === "live" ? "sk_live_" : "sk_test_";

      if (!secretKey || !secretKey.startsWith(expectedKeyPrefix)) {
        return Response.json(
          { error: `PayMongo ${mode} secret key is missing or invalid.` },
          { status: 500 },
        );
      }

      const origin = req.headers.get("origin");
      const configuredReturnUrl = Deno.env.get("PAYMONGO_RETURN_URL")?.trim();
      const localOrigin = origin &&
        /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin)
        ? origin
        : undefined;

      if (!configuredReturnUrl && !localOrigin) {
        return Response.json(
          { error: "Set PAYMONGO_RETURN_URL to the app's HTTPS return URL." },
          { status: 400 },
        );
      }

      let returnBaseUrl: URL;
      try {
        returnBaseUrl = new URL(configuredReturnUrl ?? `${localOrigin}/`);
      } catch {
        return Response.json(
          { error: "PAYMONGO_RETURN_URL is not a valid URL." },
          { status: 500 },
        );
      }

      const isLocalReturnHost = ["localhost", "127.0.0.1"].includes(
        returnBaseUrl.hostname,
      );
      if (
        returnBaseUrl.username ||
        returnBaseUrl.password ||
        (returnBaseUrl.protocol !== "https:" &&
          !(returnBaseUrl.protocol === "http:" && isLocalReturnHost))
      ) {
        return Response.json(
          { error: "PAYMONGO_RETURN_URL must use HTTPS (except local development)." },
          { status: 500 },
        );
      }

      const successUrl = new URL(returnBaseUrl);
      successUrl.searchParams.set("payment", "success");
      successUrl.searchParams.set("order_id", order.id);

      const cancelUrl = new URL(returnBaseUrl);
      cancelUrl.searchParams.set("payment", "cancelled");
      cancelUrl.searchParams.set("order_id", order.id);

      const response = await fetch(
        "https://api.paymongo.com/v2/checkout_sessions",
        {
          method: "POST",
          headers: {
            Authorization: `Basic ${btoa(secretKey + ":")}`,
            "Content-Type": "application/json",
            Accept: "application/json",
          },
          body: JSON.stringify({
            data: {
              attributes: {
                line_items: lineItems,
                payment_method_types: ["qrph", "gcash", "paymaya", "card"],
                reference_number: order.order_number,
                description: `Lunéa Beauti order ${order.order_number}`,
                success_url: successUrl.toString(),
                cancel_url: cancelUrl.toString(),
              },
            },
          }),
        },
      );

      const result = await response.json();

      if (!response.ok) {
        console.error("PayMongo checkout creation failed:", response.status);
        return Response.json(
          { error: "PayMongo could not create checkout. Check API settings." },
          { status: 502 },
        );
      }

      const checkoutUrl = result?.data?.attributes?.checkout_url;
      const sessionId = result?.data?.id;

      if (!checkoutUrl || !sessionId) {
        return Response.json(
          { error: "PayMongo returned an incomplete checkout session." },
          { status: 502 },
        );
      }

      return Response.json({
        checkout_url: checkoutUrl,
        checkout_session_id: sessionId,
        order_id: order.id,
      });
    } catch (error) {
      console.error("Checkout function error:", error);
      return Response.json(
        { error: "Unable to create checkout session." },
        { status: 500 },
      );
    }
  }),
};
