do $migration$
declare
  function_definition text;
  updated_definition text;
  old_shipping constant text := $old$  v_shipping := CASE
    WHEN v_subtotal >= 1500 THEN 0
    ELSE 60
  END;$old$;
  new_shipping constant text := $new$  v_shipping := 0;$new$;
begin
  select pg_get_functiondef(
    'public.place_customer_order(text,text,text,text,text,jsonb)'::regprocedure
  )
  into function_definition;

  if position($zero$  v_shipping := 0;$zero$ in function_definition) > 0 then
    return;
  end if;

  updated_definition := replace(
    function_definition,
    old_shipping,
    new_shipping
  );

  if updated_definition = function_definition then
    raise exception 'Could not locate the expected shipping calculation in place_customer_order.';
  end if;

  execute updated_definition;
end;
$migration$;