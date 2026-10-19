
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return Response.json({ error: "Method not allowed" }, { status: 405 });
  }

  const secret = Deno.env.get("PAYMONGO_WEBHOOK_SECRET");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const mode = (Deno.env.get("PAYMONGO_MODE") ?? "test")
    .trim()
    .toLowerCase();

  if (
    !secret ||
    !supabaseUrl ||
    !serviceKey ||
    (mode !== "test" && mode !== "live")
  ) {
    console.error("Webhook environment is not configured");
    return Response.json({ error: "Server configuration error" }, { status: 500 });
  }

  const rawBody = await req.text();
  const header = req.headers.get("Paymongo-Signature");

  if (!header) {
    return Response.json({ error: "Missing signature" }, { status: 401 });
  }

  const parts = Object.fromEntries(
    header.split(",").map((part) => {
      const index = part.indexOf("=");
      return [part.slice(0, index).trim(), part.slice(index + 1).trim()];
    }),
  );

  const timestamp = parts.t;
  const suppliedSignature = mode === "live" ? parts.li : parts.te;

  if (!timestamp || !suppliedSignature) {
    return Response.json({ error: "Invalid signature header" }, { status: 401 });
  }

  const timestampNumber = Number(timestamp);
  if (
    !Number.isFinite(timestampNumber) ||
    Math.abs(Date.now() / 1000 - timestampNumber) > 300
  ) {
    return Response.json({ error: "Expired signature" }, { status: 401 });
  }

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(`${timestamp}.${rawBody}`),
  );

  const expectedSignature = Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");

  const encoder = new TextEncoder();
  const a = encoder.encode(expectedSignature);
  const b = encoder.encode(suppliedSignature);

  let mismatch = a.length ^ b.length;

for (let i = 0; i < Math.min(a.length, b.length); i++) {
  mismatch |= a[i] ^ b[i];
}

if (mismatch !== 0) {
  return Response.json(
    { error: "Invalid signature" },
    { status: 401 },
  );
}

  let event: any;
  try {
    event = JSON.parse(rawBody);
  } catch {
    return Response.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const attributes = event?.data?.attributes;
  if (attributes?.type !== "checkout_session.payment.paid") {
    return Response.json({ received: true });
  }

  const session = attributes?.data;
  const sessionAttributes = session?.attributes;
  const reference = sessionAttributes?.reference_number;
  const paid = sessionAttributes?.payments?.some(
    (payment: any) => payment?.attributes?.status === "paid",
  );

  if (attributes?.livemode !== (mode === "live") || !reference || !paid) {
    return Response.json(
      { error: "Payment mode or payment status could not be verified." },
      { status: 400 },
    );
  }

  const supabase = createClient(supabaseUrl, serviceKey);

  const { data: order, error: lookupError } = await supabase
    .from("orders")
    .select("id, payment_status")
    .eq("order_number", reference)
    .maybeSingle();

  if (lookupError || !order) {
    console.error("Order lookup failed", lookupError?.message);
    return Response.json({ error: "Order not found" }, { status: 404 });
  }

  if (order.payment_status !== "paid") {
    const { error: updateError } = await supabase
      .from("orders")
      .update({ payment_status: "paid" })
      .eq("id", order.id)
      .eq("payment_status", "pending");

    if (updateError) {
      console.error("Order update failed", updateError.message);
      return Response.json({ error: "Could not update order" }, { status: 500 });
    }
  }

  return Response.json({ received: true });
});
