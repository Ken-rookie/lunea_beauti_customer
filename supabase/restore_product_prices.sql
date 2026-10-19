-- Restore the active product prices captured before the temporary ₱1 test-price update.
update public.products as product
set
  price = original.price,
  sale_price = original.sale_price
from (
  values
    ('51c0c9f9-8d39-4d5a-b27c-f508ad5d7110'::uuid, 45.00::numeric, null::numeric),
    ('bb38b32d-fe06-4c71-a9d2-7f395294061d'::uuid, 61.00::numeric, null::numeric),
    ('47ff791a-c3c5-4507-95a1-18922fe37cb3'::uuid, 76.00::numeric, 49.00::numeric),
    ('664bc770-cdb0-40bf-b379-83bf7ec17413'::uuid, 260.00::numeric, 149.00::numeric),
    ('c0927ef5-3fad-4e6c-acb5-b89b9f04540e'::uuid, 69.00::numeric, null::numeric),
    ('27880631-dd78-414f-958e-e33f27e99f69'::uuid, 83.00::numeric, null::numeric),
    ('682f478c-b431-4a59-8d02-63c036bb7848'::uuid, 150.00::numeric, null::numeric),
    ('c7422f92-4998-4fbb-964c-caeced20a381'::uuid, 148.00::numeric, null::numeric),
    ('6d69ec62-7505-4578-b925-2ef3fbfdc240'::uuid, 178.00::numeric, null::numeric),
    ('7b157e0c-1b17-42e1-9158-3d917ed175c6'::uuid, 80.00::numeric, null::numeric)
) as original(id, price, sale_price)
where product.id = original.id;
