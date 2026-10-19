do $migration$
declare
  function_definition text;
  updated_definition text;
  old_methods constant text := $old$'GCash', 'Maya', 'Credit/Debit Card', 'COD'$old$;
  new_methods constant text := $new$'GCash', 'Maya', 'Credit/Debit Card', 'COD', 'PayMongo'$new$;
begin
  select pg_get_functiondef(
    'public.place_customer_order(text,text,text,text,text,jsonb)'::regprocedure
  )
  into function_definition;

  if position($paymongo$'PayMongo'$paymongo$ in function_definition) > 0 then
    return;
  end if;

  updated_definition := replace(function_definition, old_methods, new_methods);

  if updated_definition = function_definition then
    raise exception 'Could not locate the expected payment-method validation in place_customer_order.';
  end if;

  execute updated_definition;
end;
$migration$;
