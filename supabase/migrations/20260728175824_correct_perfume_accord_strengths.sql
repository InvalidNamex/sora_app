-- Fragrantica main-accord bar strengths retrieved on 2026-07-28.
-- These values describe relative perceived prominence within each perfume.
-- They are not perfume formula or ingredient percentages.

create temp table perfume_accord_strength_import (
  match_name_en text primary key,
  source_url text not null,
  accords_en text[] not null,
  accords_ar text[] not null,
  percentages smallint[] not null
) on commit drop;

insert into perfume_accord_strength_import (
  match_name_en,
  source_url,
  accords_en,
  accords_ar,
  percentages
)
values
  (
    'Imagination',
    'https://www.fragrantica.com/perfume/Louis-Vuitton/Imagination-67370.html',
    array['Citrus', 'Fresh Spicy', 'Fresh', 'Green', 'Amber', 'Aromatic', 'Sweet', 'White Floral'],
    array['حمضي', 'حار منعش', 'منعش', 'أخضر', 'عنبري', 'أروماتك', 'حلو', 'زهور بيضاء'],
    array[100, 37, 29, 28, 14, 12, 9, 8]::smallint[]
  ),
  (
    'Sauvage',
    'https://www.fragrantica.com/perfume/Dior/Sauvage-31861.html',
    array['Fresh Spicy', 'Amber', 'Citrus', 'Aromatic', 'Musky', 'Woody', 'Lavender', 'Herbal'],
    array['حار منعش', 'عنبري', 'حمضي', 'أروماتك', 'مسكي', 'خشبي', 'لافندر', 'عشبي'],
    array[100, 58, 56, 48, 39, 35, 24, 22]::smallint[]
  ),
  (
    'Acqua di Gio',
    'https://www.fragrantica.com/perfume/Giorgio-Armani/Acqua-di-Gio-410.html',
    array['Citrus', 'Aromatic', 'Marine', 'Fresh Spicy', 'Floral', 'Woody', 'Fresh', 'White Floral'],
    array['حمضي', 'أروماتك', 'بحري', 'حار منعش', 'زهري', 'خشبي', 'منعش', 'زهور بيضاء'],
    array[100, 51, 40, 30, 25, 22, 21, 17]::smallint[]
  ),
  (
    'Stronger With You',
    'https://www.fragrantica.com/perfume/Giorgio-Armani/Emporio-Armani-Stronger-With-You-45258.html',
    array['Vanilla', 'Sweet', 'Balsamic', 'Nutty', 'Aromatic', 'Powdery', 'Lavender', 'Herbal'],
    array['فانيليا', 'حلو', 'بلسمي', 'جوزي', 'أروماتك', 'بودري', 'لافندر', 'عشبي'],
    array[100, 44, 37, 34, 32, 27, 26, 24]::smallint[]
  ),
  (
    'Wanted',
    'https://www.fragrantica.com/perfume/Azzaro/Wanted-38686.html',
    array['Aromatic', 'Fresh Spicy', 'Citrus', 'Fresh', 'Amber', 'Woody', 'Warm Spicy', 'Fruity'],
    array['أروماتك', 'حار منعش', 'حمضي', 'منعش', 'عنبري', 'خشبي', 'حار دافئ', 'فاكهي'],
    array[100, 79, 51, 51, 49, 48, 43, 36]::smallint[]
  ),
  (
    'Dior Homme Intense',
    'https://www.fragrantica.com/perfume/Dior/Dior-Homme-Intense-2011-13016.html',
    array['Iris', 'Woody', 'Powdery', 'Earthy', 'Aromatic', 'Violet', 'Floral', 'Lavender'],
    array['سوسن', 'خشبي', 'بودري', 'ترابي', 'أروماتك', 'بنفسج', 'زهري', 'لافندر'],
    array[100, 75, 68, 55, 51, 50, 48, 47]::smallint[]
  ),
  (
    'Tygar Bvlgari',
    'https://www.fragrantica.com/perfume/Bvlgari/Tygar-41222.html',
    array['Citrus', 'Musky', 'Amber', 'Fresh Spicy', 'Aromatic', 'Woody', 'Earthy', 'Fresh'],
    array['حمضي', 'مسكي', 'عنبري', 'حار منعش', 'أروماتك', 'خشبي', 'ترابي', 'منعش'],
    array[100, 96, 85, 55, 40, 27, 22, 17]::smallint[]
  ),
  (
    'Aventus Creed',
    'https://www.fragrantica.com/perfume/Creed/Aventus-9828.html',
    array['Fruity', 'Sweet', 'Woody', 'Leather', 'Citrus', 'Smoky', 'Musky', 'Fresh'],
    array['فاكهي', 'حلو', 'خشبي', 'جلود', 'حمضي', 'مدخن', 'مسكي', 'منعش'],
    array[100, 55, 54, 48, 42, 38, 36, 32]::smallint[]
  ),
  (
    'Dark Temptation AXE',
    'https://www.fragrantica.com/perfume/AXE/Dark-Temptation-29897.html',
    array['Sweet', 'Vanilla', 'Chocolate', 'Warm Spicy', 'Amber', 'Cacao', 'Patchouli', 'Cherry'],
    array['حلو', 'فانيليا', 'شوكولاتة', 'حار دافئ', 'عنبري', 'كاكاو', 'باتشولي', 'كرز'],
    array[100, 81, 72, 71, 32, 27, 25, 24]::smallint[]
  ),
  (
    'Black XS',
    'https://www.fragrantica.com/perfume/Paco-Rabanne/Black-XS-514.html',
    array['Sweet', 'Warm Spicy', 'Citrus', 'Amber', 'Aromatic', 'Woody', 'Balsamic', 'Cinnamon'],
    array['حلو', 'حار دافئ', 'حمضي', 'عنبري', 'أروماتك', 'خشبي', 'بلسمي', 'قرفة'],
    array[100, 99, 74, 61, 57, 51, 47, 45]::smallint[]
  ),
  (
    'Althair',
    'https://www.fragrantica.com/perfume/Parfums-de-Marly/Althair-84109.html',
    array['Sweet', 'Vanilla', 'Warm Spicy', 'Cinnamon', 'Aromatic', 'Musky', 'Powdery', 'Citrus'],
    array['حلو', 'فانيليا', 'حار دافئ', 'قرفة', 'أروماتك', 'مسكي', 'بودري', 'حمضي'],
    array[100, 95, 80, 51, 45, 43, 43, 39]::smallint[]
  ),
  (
    'Eros',
    'https://www.fragrantica.com/perfume/Versace/Eros-16657.html',
    array['Vanilla', 'Aromatic', 'Green', 'Fresh Spicy', 'Amber', 'Citrus', 'Fruity', 'Woody'],
    array['فانيليا', 'أروماتك', 'أخضر', 'حار منعش', 'عنبري', 'حمضي', 'فاكهي', 'خشبي'],
    array[100, 91, 85, 52, 46, 37, 37, 33]::smallint[]
  ),
  (
    'Bleu de Chanel',
    'https://www.fragrantica.com/perfume/Chanel/Bleu-de-Chanel-9099.html',
    array['Citrus', 'Woody', 'Fresh Spicy', 'Aromatic', 'Amber', 'Smoky', 'Balsamic', 'Warm Spicy'],
    array['حمضي', 'خشبي', 'حار منعش', 'أروماتك', 'عنبري', 'مدخن', 'بلسمي', 'حار دافئ'],
    array[100, 75, 72, 57, 53, 32, 29, 29]::smallint[]
  ),
  (
    'Eternity',
    'https://www.fragrantica.com/perfume/Calvin-Klein/Eternity-For-Men-258.html',
    array['Aromatic', 'Citrus', 'Fresh Spicy', 'Woody', 'Lavender', 'White Floral', 'Herbal', 'Green'],
    array['أروماتك', 'حمضي', 'حار منعش', 'خشبي', 'لافندر', 'زهور بيضاء', 'عشبي', 'أخضر'],
    array[100, 71, 61, 46, 40, 36, 35, 20]::smallint[]
  ),
  (
    'Yara Candy',
    'https://www.fragrantica.com/perfume/Lattafa-Perfumes/Yara-Candy-95752.html',
    array['Vanilla', 'Fruity', 'Powdery', 'Citrus', 'White Floral', 'Aromatic', 'Woody', 'Musky'],
    array['فانيليا', 'فاكهي', 'بودري', 'حمضي', 'زهور بيضاء', 'أروماتك', 'خشبي', 'مسكي'],
    array[100, 77, 66, 58, 51, 50, 46, 40]::smallint[]
  ),
  (
    'Scandal',
    'https://www.fragrantica.com/perfume/Jean-Paul-Gaultier/Scandal-45651.html',
    array['Honey', 'Sweet', 'White Floral', 'Citrus', 'Caramel', 'Animalic', 'Beeswax', 'Patchouli'],
    array['عسل', 'حلو', 'زهور بيضاء', 'حمضي', 'كراميل', 'حيواني', 'شمع العسل', 'باتشولي'],
    array[100, 73, 64, 48, 39, 34, 34, 29]::smallint[]
  ),
  (
    'La vie est belle',
    'https://www.fragrantica.com/perfume/Lancome/La-Vie-Est-Belle-14982.html',
    array['Sweet', 'Vanilla', 'Fruity', 'Patchouli', 'Woody', 'White Floral', 'Powdery', 'Iris'],
    array['حلو', 'فانيليا', 'فاكهي', 'باتشولي', 'خشبي', 'زهور بيضاء', 'بودري', 'سوسن'],
    array[100, 74, 51, 40, 39, 35, 33, 27]::smallint[]
  ),
  (
    'Burberry Her',
    'https://www.fragrantica.com/perfume/Burberry/Burberry-Her-51694.html',
    array['Fruity', 'Sweet', 'Woody', 'Musky', 'Powdery', 'Vanilla', 'Amber', 'Cherry'],
    array['فاكهي', 'حلو', 'خشبي', 'مسكي', 'بودري', 'فانيليا', 'عنبري', 'كرز'],
    array[100, 69, 30, 29, 29, 16, 14, 13]::smallint[]
  ),
  (
    'Touch Of Pink',
    'https://www.fragrantica.com/perfume/Lacoste-Fragrances/Touch-of-Pink-673.html',
    array['Citrus', 'Powdery', 'Sweet', 'Fruity', 'Vanilla', 'Aromatic', 'Musky', 'Warm Spicy'],
    array['حمضي', 'بودري', 'حلو', 'فاكهي', 'فانيليا', 'أروماتك', 'مسكي', 'حار دافئ'],
    array[100, 61, 47, 42, 38, 37, 36, 34]::smallint[]
  ),
  (
    'Kayali Marshmallow',
    'https://www.fragrantica.com/perfume/Kayali-Fragrances/Yum-Boujee-Marshmallow-81-99254.html',
    array['Sweet', 'Vanilla', 'Fruity', 'Powdery', 'Lactonic', 'Musky', 'Coconut', 'Floral'],
    array['حلو', 'فانيليا', 'فاكهي', 'بودري', 'حليبي', 'مسكي', 'جوز الهند', 'زهري'],
    array[100, 48, 38, 27, 14, 12, 9, 4]::smallint[]
  ),
  (
    'Cool Water',
    'https://www.fragrantica.com/perfume/Davidoff/Cool-Water-508.html',
    array['Fresh', 'Floral', 'Fruity', 'Aquatic', 'Ozonic', 'Sweet', 'White Floral', 'Citrus'],
    array['منعش', 'زهري', 'فاكهي', 'مائي', 'أوزوني', 'حلو', 'زهور بيضاء', 'حمضي'],
    array[100, 98, 94, 83, 72, 68, 47, 39]::smallint[]
  ),
  (
    'Madawy Gold',
    'https://www.fragrantica.com/perfume/Arabian-Oud/Madawi-Gold-Edition-92704.html',
    array['Vanilla', 'Fruity', 'Sweet', 'Warm Spicy', 'Aromatic', 'White Floral', 'Amber', 'Patchouli'],
    array['فانيليا', 'فاكهي', 'حلو', 'حار دافئ', 'أروماتك', 'زهور بيضاء', 'عنبري', 'باتشولي'],
    array[100, 74, 62, 58, 33, 33, 28, 27]::smallint[]
  ),
  (
    'Bianco Latte',
    'https://www.fragrantica.com/perfume/Giardini-Di-Toscana/Bianco-Latte-64757.html',
    array['Vanilla', 'Sweet', 'Caramel', 'Honey', 'Balsamic', 'Powdery', 'Musky', 'Aromatic'],
    array['فانيليا', 'حلو', 'كراميل', 'عسل', 'بلسمي', 'بودري', 'مسكي', 'أروماتك'],
    array[100, 84, 70, 38, 37, 37, 26, 23]::smallint[]
  ),
  (
    'Baccarat Rouge 540',
    'https://www.fragrantica.com/perfume/Maison-Francis-Kurkdjian/Baccarat-Rouge-540-33519.html',
    array['Woody', 'Amber', 'Warm Spicy', 'Metallic', 'Fresh Spicy', 'Animalic', 'Aromatic', 'White Floral'],
    array['خشبي', 'عنبري', 'حار دافئ', 'معدني', 'حار منعش', 'حيواني', 'أروماتك', 'زهور بيضاء'],
    array[100, 98, 58, 24, 23, 22, 22, 22]::smallint[]
  ),
  (
    'Khamra Qahwa',
    'https://www.fragrantica.com/perfume/Lattafa-Perfumes/Khamrah-Qahwa-88175.html',
    array['Warm Spicy', 'Sweet', 'Vanilla', 'Cinnamon', 'Coffee', 'Amber', 'Powdery', 'Aromatic'],
    array['حار دافئ', 'حلو', 'فانيليا', 'قرفة', 'قهوة', 'عنبري', 'بودري', 'أروماتك'],
    array[100, 82, 74, 49, 44, 31, 21, 19]::smallint[]
  ),
  (
    'God Of Fire',
    'https://www.fragrantica.com/perfume/Stephane-Humbert-Lucas-777/God-of-Fire-72381.html',
    array['Fruity', 'Tropical', 'Sweet', 'Citrus', 'Fresh', 'Woody', 'Fresh Spicy', 'Musky'],
    array['فاكهي', 'استوائي', 'حلو', 'حمضي', 'منعش', 'خشبي', 'حار منعش', 'مسكي'],
    array[100, 81, 73, 50, 41, 40, 38, 30]::smallint[]
  ),
  (
    'Tuscan Leather',
    'https://www.fragrantica.com/perfume/Tom-Ford/Tuscan-Leather-1849.html',
    array['Leather', 'Fruity', 'Animalic', 'Sweet', 'Amber', 'Smoky', 'Warm Spicy', 'Woody'],
    array['جلود', 'فاكهي', 'حيواني', 'حلو', 'عنبري', 'مدخن', 'حار دافئ', 'خشبي'],
    array[100, 37, 36, 26, 25, 21, 21, 20]::smallint[]
  ),
  (
    'Erba Pura',
    'https://www.fragrantica.com/perfume/Xerjoff/Erba-Pura-55157.html',
    array['Citrus', 'Fruity', 'Sweet', 'Musky', 'Powdery', 'Vanilla', 'Amber', 'Fresh Spicy'],
    array['حمضي', 'فاكهي', 'حلو', 'مسكي', 'بودري', 'فانيليا', 'عنبري', 'حار منعش'],
    array[100, 98, 76, 63, 53, 46, 36, 23]::smallint[]
  ),
  (
    'BMW M 2025',
    'https://www.fragrantica.com/perfume/BMW-Fragrances/BMW-M-2025-115749.html',
    array['Warm Spicy', 'Aromatic', 'Lavender', 'Cinnamon', 'Fresh Spicy', 'Amber', 'Woody', 'Patchouli'],
    array['حار دافئ', 'أروماتك', 'لافندر', 'قرفة', 'حار منعش', 'عنبري', 'خشبي', 'باتشولي'],
    array[100, 98, 78, 70, 70, 62, 53, 47]::smallint[]
  ),
  (
    'Don',
    'https://www.fragrantica.com/perfume/Xerjoff/Don-26709.html',
    array['Tobacco', 'Whiskey', 'Sweet', 'Smoky', 'Woody', 'Caramel', 'Aromatic', 'Warm Spicy'],
    array['تبغ', 'ويسكي', 'حلو', 'مدخن', 'خشبي', 'كراميل', 'أروماتك', 'حار دافئ'],
    array[100, 99, 94, 78, 47, 29, 24, 24]::smallint[]
  ),
  (
    'Rose Oud',
    'https://www.fragrantica.com/perfume/By-Kilian/Rose-Oud-8070.html',
    array['Rose', 'Oud', 'Woody', 'Warm Spicy', 'Floral', 'Metallic', 'Leather', 'Fresh Spicy'],
    array['ورد', 'عود', 'خشبي', 'حار دافئ', 'زهري', 'معدني', 'جلود', 'حار منعش'],
    array[100, 64, 48, 38, 30, 21, 17, 13]::smallint[]
  ),
  (
    'Tobacco Vanille',
    'https://www.fragrantica.com/perfume/Tom-Ford/Tobacco-Vanille-1825.html',
    array['Vanilla', 'Sweet', 'Tobacco', 'Warm Spicy', 'Fruity', 'Woody', 'Cacao', 'Powdery'],
    array['فانيليا', 'حلو', 'تبغ', 'حار دافئ', 'فاكهي', 'خشبي', 'كاكاو', 'بودري'],
    array[100, 92, 79, 60, 44, 35, 33, 28]::smallint[]
  );

do $validation$
begin
  if (
    select count(*)
    from perfume_accord_strength_import
  ) <> 32 then
    raise exception 'Expected exactly 32 perfume accord profiles.';
  end if;

  if exists (
    select 1
    from perfume_accord_strength_import
    where
      cardinality(accords_en) = 0
      or cardinality(accords_en) <> cardinality(accords_ar)
      or cardinality(accords_en) <> cardinality(percentages)
      or percentages[1] <> 100
      or not (
        0 <= all (percentages)
        and 100 >= all (percentages)
      )
      or exists (
        select 1
        from generate_subscripts(percentages, 1) as position
        where
          position > 1
          and percentages[position] > percentages[position - 1]
      )
  ) then
    raise exception 'Invalid perfume accord strength profile.';
  end if;

  if exists (
    select 1
    from perfume_accord_strength_import as source
    left join public.items as item
      on lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en))
    group by source.match_name_en
    having count(item.id) <> 1
  ) then
    raise exception 'Every accord profile must match exactly one item.';
  end if;
end
$validation$;

update public.items as item
set
  accords = source.accords_ar,
  "accordsEN" = source.accords_en,
  "accordPercentages" = source.percentages
from perfume_accord_strength_import as source
where lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en));

comment on column public.items."accordPercentages" is
  'Relative perceived accord prominence normalized to 100 within each perfume; aligned by position with accords and accordsEN. These are not formula percentages.';

do $verification$
begin
  if (
    select count(*)
    from public.items as item
    join perfume_accord_strength_import as source
      on lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en))
    where
      item.accords = source.accords_ar
      and item."accordsEN" = source.accords_en
      and item."accordPercentages" = source.percentages
  ) <> 32 then
    raise exception 'Perfume accord strength correction failed verification.';
  end if;
end
$verification$;
