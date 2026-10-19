-- Fill only missing product image URLs with the app's existing category photos.
-- Existing product images are left unchanged.
update public.products as product
set image_url = case
  when lower(category.name) like '%face%' then
    'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=85'
  when lower(category.name) like '%eye%' then
    'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?auto=format&fit=crop&w=900&q=85'
  when lower(category.name) like '%lip%' then
    'https://images.unsplash.com/photo-1586495777744-4413f21062fa?auto=format&fit=crop&w=900&q=85'
  when lower(category.name) like '%cheek%' then
    'https://images.unsplash.com/photo-1599733589046-10c005739ef7?auto=format&fit=crop&w=900&q=85'
end
from public.categories as category
where product.category_id = category.id
  and nullif(btrim(product.image_url), '') is null
  and (
    lower(category.name) like '%face%'
    or lower(category.name) like '%eye%'
    or lower(category.name) like '%lip%'
    or lower(category.name) like '%cheek%'
  );