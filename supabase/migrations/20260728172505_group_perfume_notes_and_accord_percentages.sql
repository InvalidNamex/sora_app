-- Generated from details.csv.
-- Re-run tool/generate_perfume_metadata_migration.rb to regenerate this file.

alter table public.items
  add column "topNotes" text[] not null default '{}'::text[],
  add column "topNotesEN" text[] not null default '{}'::text[],
  add column "middleNotes" text[] not null default '{}'::text[],
  add column "middleNotesEN" text[] not null default '{}'::text[],
  add column "baseNotes" text[] not null default '{}'::text[],
  add column "baseNotesEN" text[] not null default '{}'::text[],
  add column "accordPercentages" smallint[] not null default '{}'::smallint[];

comment on column public.items."topNotes" is
  'Ordered Arabic top-note names.';
comment on column public.items."topNotesEN" is
  'Ordered English top-note names.';
comment on column public.items."middleNotes" is
  'Ordered Arabic middle-note names.';
comment on column public.items."middleNotesEN" is
  'Ordered English middle-note names.';
comment on column public.items."baseNotes" is
  'Ordered Arabic base-note names.';
comment on column public.items."baseNotesEN" is
  'Ordered English base-note names.';
comment on column public.items."accordPercentages" is
  'Accord intensity percentages aligned by position with accords and accordsEN.';

create temporary table perfume_metadata_import (
  match_name_en text primary key,
  top_notes_en text[] not null,
  top_notes_ar text[] not null,
  middle_notes_en text[] not null,
  middle_notes_ar text[] not null,
  base_notes_en text[] not null,
  base_notes_ar text[] not null,
  accords_en text[] not null,
  accords_ar text[] not null,
  accord_percentages smallint[] not null
) on commit drop;

insert into perfume_metadata_import (
  match_name_en,
  top_notes_en,
  top_notes_ar,
  middle_notes_en,
  middle_notes_ar,
  base_notes_en,
  base_notes_ar,
  accords_en,
  accords_ar,
  accord_percentages
)
select
  source.match_name_en,
  array(select jsonb_array_elements_text(source.top_notes_en)),
  array(select jsonb_array_elements_text(source.top_notes_ar)),
  array(select jsonb_array_elements_text(source.middle_notes_en)),
  array(select jsonb_array_elements_text(source.middle_notes_ar)),
  array(select jsonb_array_elements_text(source.base_notes_en)),
  array(select jsonb_array_elements_text(source.base_notes_ar)),
  array(select jsonb_array_elements_text(source.accords_en)),
  array(select jsonb_array_elements_text(source.accords_ar)),
  array(
    select jsonb_array_elements_text(source.accord_percentages)::smallint
  )
from jsonb_to_recordset(
  $perfume_metadata$[{"match_name_en":"Imagination","top_notes_en":["Citron","Calabrian bergamot","Sicilian Orange"],"top_notes_ar":["الكباد","برغموت كالابريا","البرتقال الصقلي"],"middle_notes_en":["Tunisian Neroli","Nigerian Ginger","Ceylon Cinnamon"],"middle_notes_ar":["زهر البرتقال التونسي","الزنجبيل النيجيري","قرفة سيلان"],"base_notes_en":["Chinese Black Tea","Ambroxan","Guaiac Wood","Olibanum"],"base_notes_ar":["الشاي الأسود الصيني","الأمبروكسان","خشب الغاياك","اللبان"],"accords_en":["Citrus","Fresh","Green","Warm Spicy","Aromatic","Woody"],"accords_ar":["حمضي","منعش","أخضر","حار دافئ","أروماتك","خشبي"],"accord_percentages":[100,85,70,65,60,50]},{"match_name_en":"Sauvage","top_notes_en":["Calabrian bergamot","Pepper"],"top_notes_ar":["برغموت كالابريا","الفلفل"],"middle_notes_en":["Sichuan Pepper","Lavender","Pink Pepper","Vetiver","Patchouli","Geranium","Elemi"],"middle_notes_ar":["فلفل سيتشوان","الخزامى (اللافندر)","الفلفل الوردي","نجيل الهند","الباتشولي","إبرة الراعي","الإليمي"],"base_notes_en":["Ambroxan","Cedar","Labdanum"],"base_notes_ar":["الأمبروكسان","خشب الأرز","اللابدانوم"],"accords_en":["Fresh Spicy","Amber","Citrus","Aromatic","Musky","Woody"],"accords_ar":["حار منعش","عنبري","حمضي","أروماتك","مسكي","خشبي"],"accord_percentages":[100,90,80,75,60,50]},{"match_name_en":"Acqua di Gio","top_notes_en":["Lime","Lemon","Bergamot","Jasmine","Orange","Mandarin Orange","Neroli"],"top_notes_ar":["الليمون البنزهير","الليمون","البرغموت","الياسمين","البرتقال","اليوسفي","زهر البرتقال"],"middle_notes_en":["Sea Notes","Jasmine","Calone","Peach","Freesia","Cyclamen","Hiacynth","Violet","Rosemary","Coriander","Nutmeg","Rose","Mignonette"],"middle_notes_ar":["نسيم البحر","الياسمين","الكالون","الخوخ","الفريزيا","بخور مريم","الياقوتية","البنفسج","إكليل الجبل","الكزبرة","جوزة الطيب","الورد","المينيونيت"],"base_notes_en":["White Musk","Cedar","Oakmoss","Patchouli","Amber"],"base_notes_ar":["المسك الأبيض","خشب الأرز","طحلب البلوط","الباتشولي","العنبر"],"accords_en":["Citrus","Aromatic","Marine","Fresh Spicy","Floral","Woody"],"accords_ar":["حمضي","أروماتك","بحري","حار منعش","زهري","خشبي"],"accord_percentages":[100,90,85,70,60,50]},{"match_name_en":"Stronger With You","top_notes_en":["Cardamom","Pink Pepper","Violet Leaf","Mint"],"top_notes_ar":["الحبهان (الهيل)","الفلفل الوردي","أوراق البنفسج","النعناع"],"middle_notes_en":["Pineapple","Cinnamon","Melon","Sage","Lavender"],"middle_notes_ar":["الأناناس","القرفة","البطيخ","المريمية","الخزامى (اللافندر)"],"base_notes_en":["Vanilla","Chestnut","Amberwood","Cedar","Guaiac Wood"],"base_notes_ar":["الفانيليا","الكستناء","خشب العنبر","خشب الأرز","خشب الغاياك"],"accords_en":["Warm Spicy","Vanilla","Sweet","Aromatic","Woody","Fruity"],"accords_ar":["حار دافئ","فانيليا","حلو","أروماتك","خشبي","فاكهي"],"accord_percentages":[100,90,85,70,65,50]},{"match_name_en":"Wanted","top_notes_en":["Lemon","Ginger","Lavender","Mint"],"top_notes_ar":["الليمون","الزنجبيل","الخزامى (اللافندر)","النعناع"],"middle_notes_en":["Apple","Juniper","Guatemalan Cardamom","Geranium"],"middle_notes_ar":["التفاح","العرعر","حب الهال الغواتيمالي","إبرة الراعي"],"base_notes_en":["Tonka Bean","Amberwood","Haitian Vetiver"],"base_notes_ar":["حبوب التونكا","خشب العنبر","نجيل الهند الهايتي"],"accords_en":["Aromatic","Fresh Spicy","Citrus","Warm Spicy","Woody","Fruity"],"accords_ar":["أروماتك","حار منعش","حمضي","حار دافئ","خشبي","فاكهي"],"accord_percentages":[100,90,85,75,70,60]},{"match_name_en":"Dior Homme Intense","top_notes_en":["Lavender"],"top_notes_ar":["الخزامى (اللافندر)"],"middle_notes_en":["Iris","Ambrette (Musk Mallow)","Pear"],"middle_notes_ar":["السوسن","الأمبريت (مسك الملوخية)","الكمثرى"],"base_notes_en":["Virginia Cedar","Vetiver"],"base_notes_ar":["خشب الأرز من فرجينيا","نجيل الهند"],"accords_en":["Iris","Powdery","Woody","Earthy","Floral","Musky"],"accords_ar":["سوسن","بودري","خشبي","ترابي","زهري","مسكي"],"accord_percentages":[100,95,80,70,60,50]},{"match_name_en":"Tygar Bvlgari","top_notes_en":["Grapefruit"],"top_notes_ar":["الجريب فروت"],"middle_notes_en":["Woodsy Notes"],"middle_notes_ar":["ملاحظات خشبية"],"base_notes_en":["Ambroxan"],"base_notes_ar":["الأمبروكسان"],"accords_en":["Citrus","Amber","Woody","Fresh Spicy","Musky"],"accords_ar":["حمضي","عنبري","خشبي","حار منعش","مسكي"],"accord_percentages":[100,80,70,60,40]},{"match_name_en":"Aventus Creed","top_notes_en":["Pineapple","Bergamot","Black Currant","Apple"],"top_notes_ar":["الأناناس","البرغموت","الكشمش الأسود","التفاح"],"middle_notes_en":["Birch","Patchouli","Moroccan Jasmine","Rose"],"middle_notes_ar":["أخشاب البتولا","الباتشولي","الياسمين المغربي","الورد"],"base_notes_en":["Musk","Oakmoss","Ambergris","Vanilla"],"base_notes_ar":["المسك","طحلب البلوط","الآمبرغريس","الفانيليا"],"accords_en":["Fruity","Sweet","Leather","Woody","Smoky","Tropical"],"accords_ar":["فاكهي","حلو","جلود","خشبي","مدخن","استوائي"],"accord_percentages":[100,85,75,70,65,60]},{"match_name_en":"Dark Temptation AXE","top_notes_en":["Cherry","Pear","Ginger","Coriander"],"top_notes_ar":["الكرز","الكمثرى","الزنجبيل","الكزبرة"],"middle_notes_en":["Red Pepper","Sage","Basil"],"middle_notes_ar":["الفلفل الأحمر","المريمية","الريحان"],"base_notes_en":["Dark Chocolate","Vanilla","Whipped Cream","Amber","Patchouli"],"base_notes_ar":["الشوكولاتة الداكنة","الفانيليا","الكريمة المخفوقة","العنبر","الباتشولي"],"accords_en":["Sweet","Chocolate","Warm Spicy","Fruity","Vanilla","Fresh Spicy"],"accords_ar":["حلو","شوكولاتة","حار دافئ","فاكهي","فانيليا","حار منعش"],"accord_percentages":[100,95,80,70,65,50]},{"match_name_en":"Black XS","top_notes_en":["Lemon","Sage","Tagetes"],"top_notes_ar":["الليمون","المريمية","القطيفة"],"middle_notes_en":["Praline","Cinnamon","Tolu Balsam","Black Cardamom"],"middle_notes_ar":["الحلوى (البرالين)","القرفة","بلسم تولو","الهيل الأسود"],"base_notes_en":["Brazilian Rosewood","Patchouli","Black Amber"],"base_notes_ar":["خشب الورد البرازيلي","الباتشولي","العنبر الأسود"],"accords_en":["Sweet","Warm Spicy","Citrus","Amber","Woody","Aromatic"],"accords_ar":["حلو","حار دافئ","حمضي","عنبري","خشبي","أروماتك"],"accord_percentages":[100,85,80,75,70,60]},{"match_name_en":"Althair","top_notes_en":["Orange Blossom","Bergamot","Cinnamon","Cardamom"],"top_notes_ar":["زهر البرتقال","البرغموت","القرفة","الحبهان (الهيل)"],"middle_notes_en":["Bourbon Vanilla","Elemi"],"middle_notes_ar":["فانيليا بوربون","الإليمي"],"base_notes_en":["Guaiac Wood","Ambrox Super","Praline","Musk"],"base_notes_ar":["خشب الغاياك","أمبروكس سوبر","الحلوى (البرالين)","المسك"],"accords_en":["Vanilla","Sweet","Warm Spicy","Citrus","Musky","Woody"],"accords_ar":["فانيليا","حلو","حار دافئ","حمضي","مسكي","خشبي"],"accord_percentages":[100,90,85,70,65,60]},{"match_name_en":"Eros","top_notes_en":["Mint","Green Apple","Lemon"],"top_notes_ar":["النعناع","التفاح الأخضر","الليمون"],"middle_notes_en":["Tonka Bean","Ambroxan","Geranium"],"middle_notes_ar":["حبوب التونكا","الأمبروكسان","إبرة الراعي"],"base_notes_en":["Madagascar Vanilla","Virginian Cedar","Atlas Cedar","Vetiver","Oakmoss"],"base_notes_ar":["فانيليا مدغشقر","خشب الأرز من فرجينيا","خشب الأرز الأطلسي","نجيل الهند","طحلب البلوط"],"accords_en":["Vanilla","Aromatic","Green","Fresh Spicy","Fruity","Sweet"],"accords_ar":["فانيليا","أروماتك","أخضر","حار منعش","فاكهي","حلو"],"accord_percentages":[100,90,85,80,75,70]},{"match_name_en":"Bleu de Chanel","top_notes_en":["Grapefruit","Lemon","Mint","Pink Pepper"],"top_notes_ar":["الجريب فروت","الليمون","النعناع","الفلفل الوردي"],"middle_notes_en":["Ginger","Nutmeg","Jasmine","Iso E Super"],"middle_notes_ar":["الزنجبيل","جوزة الطيب","الياسمين","آيزو إي سوبر"],"base_notes_en":["Incense","Vetiver","Cedar","Sandalwood","Patchouli","Labdanum","White Musk"],"base_notes_ar":["البخور","نجيل الهند","خشب الأرز","خشب الصندل","الباتشولي","اللابدانوم","المسك الأبيض"],"accords_en":["Citrus","Woody","Warm Spicy","Aromatic","Amber","Smoky"],"accords_ar":["حمضي","خشبي","حار دافئ","أروماتك","عنبري","مدخن"],"accord_percentages":[100,95,85,80,75,65]},{"match_name_en":"Eternity","top_notes_en":["Lavender","Lemon","Bergamot","Mandarin Orange"],"top_notes_ar":["الخزامى (اللافندر)","الليمون","البرغموت","اليوسفي"],"middle_notes_en":["Sage","Juniper Berries","Basil","Geranium","Coriander","Jasmine","Lily-of-the-Valley","Orange Blossom"],"middle_notes_ar":["المريمية","توت العرعر","الريحان","إبرة الراعي","الكزبرة","الياسمين","زنبق الوادي","زهر البرتقال"],"base_notes_en":["Sandalwood","Vetiver","Musk","Brazilian Rosewood","Amber"],"base_notes_ar":["خشب الصندل","نجيل الهند","المسك","خشب الورد البرازيلي","العنبر"],"accords_en":["Aromatic","Citrus","Fresh Spicy","Floral","Woody","Herbal"],"accords_ar":["أروماتك","حمضي","حار منعش","زهري","خشبي","عشبي"],"accord_percentages":[100,85,80,75,70,65]},{"match_name_en":"Yara Candy","top_notes_en":["Candied Fruits","Tangerine","Black Currant"],"top_notes_ar":["الفواكه المسكرة","اليوسفي","الكشمش الأسود"],"middle_notes_en":["Strawberry","Vanilla Blossom","Caramel"],"middle_notes_ar":["الفراولة","زهر الفانيليا","الكراميل"],"base_notes_en":["Vanilla","Musk","Sandalwood"],"base_notes_ar":["الفانيليا","المسك","خشب الصندل"],"accords_en":["Sweet","Fruity","Vanilla","Caramel","Musky","Citrus"],"accords_ar":["حلو","فاكهي","فانيليا","كراميل","مسكي","حمضي"],"accord_percentages":[100,90,85,75,60,50]},{"match_name_en":"Scandal","top_notes_en":["Blood Orange","Mandarin Orange"],"top_notes_ar":["البرتقال الأحمر","اليوسفي"],"middle_notes_en":["Honey","Gardenia","Orange Blossom","Jasmine","Peach"],"middle_notes_ar":["العسل","الغاردينيا","زهر البرتقال","الياسمين","الخوخ"],"base_notes_en":["Beeswax","Caramel","Patchouli","Licorice"],"base_notes_ar":["شمع العسل","الكراميل","الباتشولي","العرقسوس"],"accords_en":["Honey","Sweet","White Floral","Citrus","Caramel","Patchouli"],"accords_ar":["عسل","حلو","زهور بيضاء","حمضي","كراميل","باتشولي"],"accord_percentages":[100,95,85,70,65,60]},{"match_name_en":"La vie est belle","top_notes_en":["Black Currant","Pear"],"top_notes_ar":["الكشمش الأسود","الكمثرى"],"middle_notes_en":["Iris","Jasmine","Orange Blossom"],"middle_notes_ar":["السوسن","الياسمين","زهر البرتقال"],"base_notes_en":["Praline","Vanilla","Patchouli","Tonka Bean"],"base_notes_ar":["الحلوى (البرالين)","الفانيليا","الباتشولي","حبوب التونكا"],"accords_en":["Sweet","Vanilla","Fruity","Powdery","Patchouli","White Floral"],"accords_ar":["حلو","فانيليا","فاكهي","بودري","باتشولي","زهور بيضاء"],"accord_percentages":[100,90,85,80,75,60]},{"match_name_en":"Burberry Her","top_notes_en":["Strawberry","Raspberry","Blackberry","Sour Cherry","Black Currant","Mandarin Orange","Lemon"],"top_notes_ar":["الفراولة","توت العليق","التوت الأسود","الكرز الحامض","الكشمش الأسود","اليوسفي","الليمون"],"middle_notes_en":["Violet","Jasmine"],"middle_notes_ar":["البنفسج","الياسمين"],"base_notes_en":["Musk","Vanilla","Cashmeran","Woody Notes","Oakmoss","Amber","Patchouli"],"base_notes_ar":["المسك","الفانيليا","الكشميران","ملاحظات خشبية","طحلب البلوط","العنبر","الباتشولي"],"accords_en":["Fruity","Sweet","Woody","Musky","Powdery","Vanilla"],"accords_ar":["فاكهي","حلو","خشبي","مسكي","بودري","فانيليا"],"accord_percentages":[100,90,75,70,65,60]},{"match_name_en":"Touch Of Pink","top_notes_en":["Orange","Peach","Blood Orange","Coriander","Cardamom"],"top_notes_ar":["البرتقال","الخوخ","البرتقال الأحمر","الكزبرة","الحبهان (الهيل)"],"middle_notes_en":["Jasmine","Coriander","Cardamom","Violet Leaf","Carrot Seeds"],"middle_notes_ar":["الياسمين","الكزبرة","الحبهان (الهيل)","أوراق البنفسج","بذور الجزر"],"base_notes_en":["Vanilla","Musk","Sandalwood"],"base_notes_ar":["الفانيليا","المسك","خشب الصندل"],"accords_en":["Citrus","Powdery","Fruity","Musky","Vanilla","Warm Spicy"],"accords_ar":["حمضي","بودري","فاكهي","مسكي","فانيليا","حار دافئ"],"accord_percentages":[100,85,80,75,70,60]},{"match_name_en":"Kayali Marshmallow","top_notes_en":["Marshmallow","Strawberry","Whipped Cream"],"top_notes_ar":["الخطمي (المارشميلو)","الفراولة","الكريمة المخفوقة"],"middle_notes_en":["Vanilla Orchid","Jasmine"],"middle_notes_ar":["أوركيد الفانيليا","الياسمين"],"base_notes_en":["Vanilla","White Musk","Sugar"],"base_notes_ar":["الفانيليا","المسك الأبيض","السكر"],"accords_en":["Sweet","Vanilla","Powdery","Lactonic","Fruity","Musky"],"accords_ar":["حلو","فانيليا","بودري","لاكتوني (حليبي)","فاكهي","مسكي"],"accord_percentages":[100,95,80,75,70,60]},{"match_name_en":"Cool Water","top_notes_en":["Melon","Lotus","Lemon","Pineapple","Quince","Calone","Lily","Black Currant"],"top_notes_ar":["البطيخ","اللوتس","الليمون","الأناناس","السفرجل","الكالون","الزنبق","الكشمش الأسود"],"middle_notes_en":["Lotus","Water Lily","Lily-of-the-Valley","Jasmine","Honey","Hawthorn","Rose"],"middle_notes_ar":["اللوتس","زنبق الماء","زنبق الوادي","الياسمين","العسل","الزعرور","الورد"],"base_notes_en":["Musk","Vetiver","Raspberry","Blackberry","Root","Peach","Sandalwood","Vanilla"],"base_notes_ar":["المسك","نجيل الهند","توت العليق","التوت الأسود","الجذور","الخوخ","خشب الصندل","الفانيليا"],"accords_en":["Floral","Aquatic","Fruity","Fresh","Ozonic","Sweet"],"accords_ar":["زهري","مائي","فاكهي","منعش","أوزوني","حلو"],"accord_percentages":[100,95,85,80,75,60]},{"match_name_en":"Madawy Gold","top_notes_en":["Cardamom","Red Fruits"],"top_notes_ar":["الحبهان (الهيل)","الفواكه الحمراء"],"middle_notes_en":["Pineapple","Jasmine","Tonka Bean"],"middle_notes_ar":["الأناناس","الياسمين","حبوب التونكا"],"base_notes_en":["Vanilla","Patchouli","Musk"],"base_notes_ar":["الفانيليا","الباتشولي","المسك"],"accords_en":["Sweet","Fruity","Vanilla","Warm Spicy","White Floral","Musky"],"accords_ar":["حلو","فاكهي","فانيليا","حار دافئ","زهور بيضاء","مسكي"],"accord_percentages":[100,90,85,75,70,60]},{"match_name_en":"Bianco Latte","top_notes_en":["Caramel"],"top_notes_ar":["الكراميل"],"middle_notes_en":["Coumarin","Honey"],"middle_notes_ar":["الكومارين","العسل"],"base_notes_en":["Vanilla","White Musk"],"base_notes_ar":["الفانيليا","المسك الأبيض"],"accords_en":["Vanilla","Sweet","Caramel","Honey","Powdery","Musky"],"accords_ar":["فانيليا","حلو","كراميل","عسل","بودري","مسكي"],"accord_percentages":[100,95,90,85,75,70]},{"match_name_en":"Baccarat Rouge 540","top_notes_en":["Saffron","Jasmine"],"top_notes_ar":["الزعفران","الياسمين"],"middle_notes_en":["Amberwood","Ambergris"],"middle_notes_ar":["خشب العنبر","الآمبرغريس"],"base_notes_en":["Fir Resin","Cedar"],"base_notes_ar":["راتنج التنوب","خشب الأرز"],"accords_en":["Woody","Amber","Warm Spicy","Fresh Spicy","Aromatic","Animalic"],"accords_ar":["خشبي","عنبري","حار دافئ","حار منعش","أروماتك","حيواني"],"accord_percentages":[100,95,85,80,75,60]},{"match_name_en":"Khamra Qahwa","top_notes_en":["Cinnamon","Cardamom","Ginger"],"top_notes_ar":["القرفة","الحبهان (الهيل)","الزنجبيل"],"middle_notes_en":["Praline","Candied Fruits","White Flowers"],"middle_notes_ar":["الحلوى (البرالين)","الفواكه المسكرة","الزهور البيضاء"],"base_notes_en":["Coffee","Vanilla","Tonka Bean","Benzoin","Musk"],"base_notes_ar":["القهوة","الفانيليا","حبوب التونكا","الجاوي","المسك"],"accords_en":["Warm Spicy","Sweet","Coffee","Vanilla","Cinnamon","Amber"],"accords_ar":["حار دافئ","حلو","قهوة","فانيليا","قرفة","عنبري"],"accord_percentages":[100,95,85,80,75,70]},{"match_name_en":"God Of Fire","top_notes_en":["Mango","Lemon","Pink Berries","Ginger"],"top_notes_ar":["المانجو","الليمون","التوت الوردي","الزنجبيل"],"middle_notes_en":["Blue Coumarin","Jasmine","Woody Notes"],"middle_notes_ar":["الكومارين الأزرق","الياسمين","ملاحظات خشبية"],"base_notes_en":["Oud","Nagarmotha","Musk","Amber"],"base_notes_ar":["العود","السيبرول (الناجارموثا)","المسك","العنبر"],"accords_en":["Fruity","Tropical","Sweet","Woody","Citrus","Fresh"],"accords_ar":["فاكهي","استوائي","حلو","خشبي","حمضي","منعش"],"accord_percentages":[100,95,85,80,75,70]},{"match_name_en":"Tuscan Leather","top_notes_en":["Raspberry","Saffron","Thyme"],"top_notes_ar":["توت العليق","الزعفران","الزعتر"],"middle_notes_en":["Olibanum","Jasmine"],"middle_notes_ar":["اللبان","الياسمين"],"base_notes_en":["Leather","Suede","Woody Notes","Amber"],"base_notes_ar":["الجلود","جلد الغزال (الشمواه)","ملاحظات خشبية","العنبر"],"accords_en":["Leather","Fruity","Animalic","Sweet","Amber","Smoky"],"accords_ar":["جلود","فاكهي","حيواني","حلو","عنبري","مدخن"],"accord_percentages":[100,85,80,75,70,65]},{"match_name_en":"Erba Pura","top_notes_en":["Sicilian Orange","Calabrian Bergamot","Sicilian Lemon"],"top_notes_ar":["البرتقال الصقلي","برغموت كالابريا","الليمون الصقلي"],"middle_notes_en":["Fruits"],"middle_notes_ar":["فواكه"],"base_notes_en":["White Musk","Madagascar Vanilla","Amber"],"base_notes_ar":["المسك الأبيض","فانيليا مدغشقر","العنبر"],"accords_en":["Fruity","Citrus","Sweet","Musky","Powdery","Vanilla"],"accords_ar":["فاكهي","حمضي","حلو","مسكي","بودري","فانيليا"],"accord_percentages":[100,90,85,80,70,65]},{"match_name_en":"BMW M 2025","top_notes_en":["Lemon","Bergamot","Metallic Notes"],"top_notes_ar":["الليمون","البرغموت","نوتات معدنية"],"middle_notes_en":["Lavender","Violet Leaf","Black Pepper"],"middle_notes_ar":["الخزامى (اللافندر)","أوراق البنفسج","الفلفل الأسود"],"base_notes_en":["Leather","Vetiver","Cedar","Musk"],"base_notes_ar":["الجلود","نجيل الهند","خشب الأرز","المسك"],"accords_en":["Citrus","Leather","Metallic","Fresh Spicy","Woody","Aromatic"],"accords_ar":["حمضي","جلود","معدني","حار منعش","خشبي","أروماتك"],"accord_percentages":[100,85,80,75,70,60]},{"match_name_en":"Don","top_notes_en":["Gunpowder","Whiskey"],"top_notes_ar":["البارود","الويسكي"],"middle_notes_en":["Tobacco"],"middle_notes_ar":["التبغ"],"base_notes_en":["Spun Sugar"],"base_notes_ar":["غزل البنات (السكر المغزول)"],"accords_en":["Tobacco","Whiskey","Sweet","Smoky","Warm Spicy"],"accords_ar":["تبغ","ويسكي","حلو","مدخن","حار دافئ"],"accord_percentages":[100,95,85,80,70]},{"match_name_en":"Rose Oud","top_notes_en":["Saffron","Cinnamon"],"top_notes_ar":["الزعفران","القرفة"],"middle_notes_en":["Rose"],"middle_notes_ar":["الورد"],"base_notes_en":["Agarwood (Oud)","Guaiac Wood","Cedar"],"base_notes_ar":["العود","خشب الغاياك","خشب الأرز"],"accords_en":["Rose","Oud","Warm Spicy","Woody","Floral","Leather"],"accords_ar":["ورد","عود","حار دافئ","خشبي","زهري","جلود"],"accord_percentages":[100,95,85,80,75,65]},{"match_name_en":"Tobacco Vanille","top_notes_en":["Tobacco Leaf","Spicy Notes"],"top_notes_ar":["أوراق التبغ","نوتات حارة"],"middle_notes_en":["Vanilla","Cacao","Tonka Bean","Tobacco Blossom"],"middle_notes_ar":["الفانيليا","الكاكاو","حبوب التونكا","زهر التبغ"],"base_notes_en":["Dried Fruits","Woody Notes"],"base_notes_ar":["الفواكه المجففة","ملاحظات خشبية"],"accords_en":["Vanilla","Sweet","Tobacco","Warm Spicy","Fruity","Cacao"],"accords_ar":["فانيليا","حلو","تبغ","حار دافئ","فاكهي","كاكاو"],"accord_percentages":[100,95,90,85,75,70]}]$perfume_metadata$::jsonb
) as source (
  match_name_en text,
  top_notes_en jsonb,
  top_notes_ar jsonb,
  middle_notes_en jsonb,
  middle_notes_ar jsonb,
  base_notes_en jsonb,
  base_notes_ar jsonb,
  accords_en jsonb,
  accords_ar jsonb,
  accord_percentages jsonb
);

do $verification$
begin
  if exists (
    select 1
    from perfume_metadata_import as source
    left join public.items as item
      on lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en))
    group by source.match_name_en
    having count(item.id) <> 1
  ) then
    raise exception
      'Every CSV perfume must match exactly one existing item.';
  end if;
end
$verification$;

update public.items as item
set
  "topNotes" = source.top_notes_ar,
  "topNotesEN" = source.top_notes_en,
  "middleNotes" = source.middle_notes_ar,
  "middleNotesEN" = source.middle_notes_en,
  "baseNotes" = source.base_notes_ar,
  "baseNotesEN" = source.base_notes_en,
  notes = source.top_notes_ar ||
    source.middle_notes_ar ||
    source.base_notes_ar,
  "notesEN" = source.top_notes_en ||
    source.middle_notes_en ||
    source.base_notes_en,
  accords = source.accords_ar,
  "accordsEN" = source.accords_en,
  "accordPercentages" = source.accord_percentages
from perfume_metadata_import as source
where lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en));

alter table public.items
  add constraint items_accord_percentages_range
    check (
      0 <= all ("accordPercentages")
      and 100 >= all ("accordPercentages")
    ),
  add constraint items_accord_metadata_lengths
    check (
      cardinality(accords) = cardinality("accordsEN")
      and cardinality(accords) = cardinality("accordPercentages")
    );

do $verification$
begin
  if (
    select count(*)
    from public.items as item
    join perfume_metadata_import as source
      on lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en))
    where
      item."topNotes" = source.top_notes_ar
      and item."topNotesEN" = source.top_notes_en
      and item."middleNotes" = source.middle_notes_ar
      and item."middleNotesEN" = source.middle_notes_en
      and item."baseNotes" = source.base_notes_ar
      and item."baseNotesEN" = source.base_notes_en
      and item.accords = source.accords_ar
      and item."accordsEN" = source.accords_en
      and item."accordPercentages" = source.accord_percentages
  ) <> 32 then
    raise exception 'Perfume metadata backfill failed verification.';
  end if;
end
$verification$;
