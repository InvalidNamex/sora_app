-- Generated from details.csv.
-- Re-run tool/generate_perfume_catalog_migration.mjs to regenerate this file.

create temporary table perfume_import (
  match_name_en text not null,
  item_name_en text not null,
  item_name_ar text not null,
  brand_name text not null,
  description_en text not null,
  description_ar text not null,
  gender integer not null,
  notes_en text[] not null,
  notes_ar text[] not null,
  accords_en text[] not null,
  accords_ar text[] not null
);

insert into perfume_import (
  match_name_en,
  item_name_en,
  item_name_ar,
  brand_name,
  description_en,
  description_ar,
  gender,
  notes_en,
  notes_ar,
  accords_en,
  accords_ar
)
select
  source.match_name_en,
  source.item_name_en,
  source.item_name_ar,
  source.brand_name,
  source.description_en,
  source.description_ar,
  source.gender,
  array(select jsonb_array_elements_text(source.notes_en)),
  array(select jsonb_array_elements_text(source.notes_ar)),
  array(select jsonb_array_elements_text(source.accords_en)),
  array(select jsonb_array_elements_text(source.accords_ar))
from jsonb_to_recordset($perfume_catalog$[{"match_name_en":"Imagination","item_name_en":"Imagination","item_name_ar":"إيماجينيشن","brand_name":"Louis Vuitton","description_en":"Imagination by Louis Vuitton is a Citrus Aromatic fragrance for men. Imagination was launched in 2021. The nose behind this fragrance is Jacques Cavallier.","description_ar":"إيماجينيشن من لويس فيتون هو عطر حمضي أروماتك للرجال. تم إطلاق إيماجينيشن في عام 2021. الأنف وراء هذا العطر هو جاك كافالييه.","gender":1,"notes_en":["Citron","Calabrian bergamot","Sicilian Orange","Tunisian Neroli","Nigerian Ginger","Ceylon Cinnamon","Chinese Black Tea","Ambroxan","Guaiac Wood","Olibanum"],"notes_ar":["الكباد","برغموت كالابريا","البرتقال الصقلي","زهر البرتقال التونسي","الزنجبيل النيجيري","قرفة سيلان","الشاي الأسود الصيني","الأمبروكسان","خشب الغاياك","اللبان"],"accords_en":["Citrus","Fresh","Green","Warm Spicy","Aromatic","Woody"],"accords_ar":["حمضي","منعش","أخضر","حار دافئ","أروماتك","خشبي"]},{"match_name_en":"Sauvage","item_name_en":"Sauvage","item_name_ar":"سوفاج","brand_name":"Dior","description_en":"Sauvage by Dior is an Aromatic Fougere fragrance for men. Sauvage was launched in 2015. The nose behind this fragrance is Francois Demachy.","description_ar":"سوفاج من ديور هو عطر أروماتك فوچير للرجال. تم إطلاق سوفاج في عام 2015. الأنف وراء هذا العطر هو فرانسوا ديماشي.","gender":1,"notes_en":["Calabrian bergamot","Pepper","Sichuan Pepper","Lavender","Pink Pepper","Vetiver","Patchouli","Geranium","Elemi","Ambroxan","Cedar","Labdanum"],"notes_ar":["برغموت كالابريا","الفلفل","فلفل سيتشوان","الخزامى (اللافندر)","الفلفل الوردي","نجيل الهند","الباتشولي","إبرة الراعي","الإليمي","الأمبروكسان","خشب الأرز","اللابدانوم"],"accords_en":["Fresh Spicy","Amber","Citrus","Aromatic","Musky","Woody"],"accords_ar":["حار منعش","عنبري","حمضي","أروماتك","مسكي","خشبي"]},{"match_name_en":"Acqua di Gio","item_name_en":"Acqua di Gio","item_name_ar":"أكوا دي جيو","brand_name":"Giorgio Armani","description_en":"Acqua di Giò by Giorgio Armani is an Aromatic Aquatic fragrance for men. Acqua di Giò was launched in 1996. Created by Alberto Morillas, Annick Menardo and Christian Dussoulier.","description_ar":"أكوا دي جيو من جيورجيو أرماني هو عطر أروماتك مائي للرجال. تم إطلاق أكوا دي جيو في عام 1996. تم ابتكاره بواسطة ألبرتو مورياس، أنيك ميناردو وكريستيان دوسولييه.","gender":1,"notes_en":["Lime","Lemon","Bergamot","Jasmine","Orange","Mandarin Orange","Neroli","Sea Notes","Calone","Peach","Freesia","Cyclamen","Hiacynth","Violet","Rosemary","Coriander","Nutmeg","Rose","Mignonette","White Musk","Cedar","Oakmoss","Patchouli","Amber"],"notes_ar":["الليمون البنزهير","الليمون","البرغموت","الياسمين","البرتقال","اليوسفي","زهر البرتقال","نسيم البحر","الكالون","الخوخ","الفريزيا","بخور مريم","الياقوتية","البنفسج","إكليل الجبل","الكزبرة","جوزة الطيب","الورد","المينيونيت","المسك الأبيض","خشب الأرز","طحلب البلوط","الباتشولي","العنبر"],"accords_en":["Citrus","Aromatic","Marine","Fresh Spicy","Floral","Woody"],"accords_ar":["حمضي","أروماتك","بحري","حار منعش","زهري","خشبي"]},{"match_name_en":"Stronger With You","item_name_en":"Stronger With You","item_name_ar":"سترونجر ويذ يو","brand_name":"Emporio Armani","description_en":"Stronger With You by Emporio Armani is an Aromatic Fougere fragrance for men. Stronger With You was launched in 2017. The nose behind this fragrance is Cecile Matton.","description_ar":"سترونجر ويذ يو من إمبوريو أرماني هو عطر أروماتك فوچير للرجال. تم إطلاق سترونجر ويذ يو في عام 2017. الأنف العطري وراء هذا العطر هي سيسيل ماتون.","gender":1,"notes_en":["Cardamom","Pink Pepper","Violet Leaf","Mint","Pineapple","Cinnamon","Melon","Sage","Lavender","Vanilla","Chestnut","Amberwood","Cedar","Guaiac Wood"],"notes_ar":["الحبهان (الهيل)","الفلفل الوردي","أوراق البنفسج","النعناع","الأناناس","القرفة","البطيخ","المريمية","الخزامى (اللافندر)","الفانيليا","الكستناء","خشب العنبر","خشب الأرز","خشب الغاياك"],"accords_en":["Warm Spicy","Vanilla","Sweet","Aromatic","Woody","Fruity"],"accords_ar":["حار دافئ","فانيليا","حلو","أروماتك","خشبي","فاكهي"]},{"match_name_en":"Wanted","item_name_en":"Wanted","item_name_ar":"وانتد","brand_name":"Azzaro","description_en":"Wanted by Azzaro is a Woody Spicy fragrance for men. Wanted was launched in 2016. The nose behind this fragrance is Fabrice Pellegrin.","description_ar":"وانتد من أزارو هو عطر خشبي حار للرجال. تم إطلاق وانتد في عام 2016. الأنف العطري وراء هذا العطر هو فابريس بيليجرين.","gender":1,"notes_en":["Lemon","Ginger","Lavender","Mint","Apple","Juniper","Guatemalan Cardamom","Geranium","Tonka Bean","Amberwood","Haitian Vetiver"],"notes_ar":["الليمون","الزنجبيل","الخزامى (اللافندر)","النعناع","التفاح","العرعر","حب الهال الغواتيمالي","إبرة الراعي","حبوب التونكا","خشب العنبر","نجيل الهند الهايتي"],"accords_en":["Aromatic","Fresh Spicy","Citrus","Warm Spicy","Woody","Fruity"],"accords_ar":["أروماتك","حار منعش","حمضي","حار دافئ","خشبي","فاكهي"]},{"match_name_en":"Dior Homme Intense","item_name_en":"Dior Homme Intense","item_name_ar":"ديور هوم إنتنس","brand_name":"Dior","description_en":"Dior Homme Intense 2011 by Dior is a Woody Floral Musk fragrance for men. Dior Homme Intense 2011 was launched in 2011. The nose behind this fragrance is Francois Demachy.","description_ar":"ديور هوم إنتنس 2011 من ديور هو عطر خشبي زهري مسكي للرجال. تم إطلاق ديور هوم إنتنس 2011 في عام 2011. الأنف العطري وراء هذا العطر هو فرانسوا ديماشي.","gender":1,"notes_en":["Lavender","Iris","Ambrette (Musk Mallow)","Pear","Virginia Cedar","Vetiver"],"notes_ar":["الخزامى (اللافندر)","السوسن","الأمبريت (مسك الملوخية)","الكمثرى","خشب الأرز من فرجينيا","نجيل الهند"],"accords_en":["Iris","Powdery","Woody","Earthy","Floral","Musky"],"accords_ar":["سوسن","بودري","خشبي","ترابي","زهري","مسكي"]},{"match_name_en":"Tygar Bvlgari","item_name_en":"Tygar Bvlgari","item_name_ar":"تايجر","brand_name":"Bvlgari","description_en":"Tygar by Bvlgari is a Citrus Aromatic fragrance for men. Tygar was launched in 2016. The nose behind this fragrance is Jacques Cavallier.","description_ar":"تايجر من بولغاري هو عطر حمضي أروماتك للرجال. تم إطلاق تايجر في عام 2016. الأنف العطري وراء هذا العطر هو جاك كافالييه.","gender":1,"notes_en":["Grapefruit","Woodsy Notes","Ambroxan"],"notes_ar":["الجريب فروت","ملاحظات خشبية","الأمبروكسان"],"accords_en":["Citrus","Amber","Woody","Fresh Spicy","Musky"],"accords_ar":["حمضي","عنبري","خشبي","حار منعش","مسكي"]},{"match_name_en":"Aventus Creed","item_name_en":"Aventus Creed","item_name_ar":"أفينتوس","brand_name":"Creed","description_en":"Aventus by Creed is a Chypre Fruity fragrance for men. Aventus was launched in 2010. Aventus was created by Jean-Christophe Hérault and Erwin Creed.","description_ar":"أفينتوس من كريد هو عطر تشيبر فاكهي للرجال. تم إطلاق أفينتوس في عام 2010. تم ابتكار أفينتوس بواسطة جان كريستوف هيرو وإروين كريد.","gender":1,"notes_en":["Pineapple","Bergamot","Black Currant","Apple","Birch","Patchouli","Moroccan Jasmine","Rose","Musk","Oakmoss","Ambergris","Vanilla"],"notes_ar":["الأناناس","البرغموت","الكشمش الأسود","التفاح","أخشاب البتولا","الباتشولي","الياسمين المغربي","الورد","المسك","طحلب البلوط","الآمبرغريس","الفانيليا"],"accords_en":["Fruity","Sweet","Leather","Woody","Smoky","Tropical"],"accords_ar":["فاكهي","حلو","جلود","خشبي","مدخن","استوائي"]},{"match_name_en":"Dark Temptation AXE","item_name_en":"Dark Temptation AXE","item_name_ar":"دارك تمبتيشن","brand_name":"AXE","description_en":"Dark Temptation by AXE is an Amber Fougere fragrance for men. Dark Temptation was launched in 2013. The nose behind this fragrance is Ann Gottlieb.","description_ar":"دارك تمبتيشن من آكس هو عطر عنبري فوچير للرجال. تم إطلاق دارك تمبتيشن في عام 2013. الأنف العطري وراء هذا العطر هي آن جوتليب.","gender":1,"notes_en":["Cherry","Pear","Ginger","Coriander","Red Pepper","Sage","Basil","Dark Chocolate","Vanilla","Whipped Cream","Amber","Patchouli"],"notes_ar":["الكرز","الكمثرى","الزنجبيل","الكزبرة","الفلفل الأحمر","المريمية","الريحان","الشوكولاتة الداكنة","الفانيليا","الكريمة المخفوقة","العنبر","الباتشولي"],"accords_en":["Sweet","Chocolate","Warm Spicy","Fruity","Vanilla","Fresh Spicy"],"accords_ar":["حلو","شوكولاتة","حار دافئ","فاكهي","فانيليا","حار منعش"]},{"match_name_en":"Black XS","item_name_en":"Black XS","item_name_ar":"بلاك إكس إس","brand_name":"Rabanne","description_en":"Black XS by Rabanne is an Amber Woody fragrance for men. Black XS was launched in 2005. The nose behind this fragrance is Olivier Cresp.","description_ar":"بلاك إكس إس من رابان هو عطر عنبري خشبي للرجال. تم إطلاق بلاك إكس إس في عام 2005. الأنف العطري وراء هذا العطر هو أوليفييه كريسب.","gender":1,"notes_en":["Lemon","Sage","Tagetes","Praline","Cinnamon","Tolu Balsam","Black Cardamom","Brazilian Rosewood","Patchouli","Black Amber"],"notes_ar":["الليمون","المريمية","القطيفة","الحلوى (البرالين)","القرفة","بلسم تولو","الهيل الأسود","خشب الورد البرازيلي","الباتشولي","العنبر الأسود"],"accords_en":["Sweet","Warm Spicy","Citrus","Amber","Woody","Aromatic"],"accords_ar":["حلو","حار دافئ","حمضي","عنبري","خشبي","أروماتك"]},{"match_name_en":"Althair","item_name_en":"Althair","item_name_ar":"الطاير","brand_name":"Parfums de Marly","description_en":"Althaïr by Parfums de Marly is an Amber Vanilla fragrance for men. Althaïr was launched in 2023. Created by Hamid Merati-Kashani and Ilias Ermenidis.","description_ar":"الطاير من بيرفيومز دي مارلي هو عطر عنبري فانيليا للرجال. تم إطلاق الطاير في عام 2023. تم ابتكاره بواسطة حامد مرآتي كاشاني وإيلياس إرمنيدس.","gender":1,"notes_en":["Orange Blossom","Bergamot","Cinnamon","Cardamom","Bourbon Vanilla","Elemi","Guaiac Wood","Ambrox Super","Praline","Musk"],"notes_ar":["زهر البرتقال","البرغموت","القرفة","الحبهان (الهيل)","فانيليا بوربون","الإليمي","خشب الغاياك","أمبروكس سوبر","الحلوى (البرالين)","المسك"],"accords_en":["Vanilla","Sweet","Warm Spicy","Citrus","Musky","Woody"],"accords_ar":["فانيليا","حلو","حار دافئ","حمضي","مسكي","خشبي"]},{"match_name_en":"Eros","item_name_en":"Eros","item_name_ar":"إيروس","brand_name":"Versace","description_en":"Eros by Versace is an Aromatic Fougere fragrance for men. Eros was launched in 2012. The nose behind this fragrance is Aurélien Guichard.","description_ar":"إيروس من فيرساتشي هو عطر أروماتك فوچير للرجال. تم إطلاق إيروس في عام 2012. الأنف العطري وراء هذا العطر هو أوريليان جيتشارد.","gender":1,"notes_en":["Mint","Green Apple","Lemon","Tonka Bean","Ambroxan","Geranium","Madagascar Vanilla","Virginian Cedar","Atlas Cedar","Vetiver","Oakmoss"],"notes_ar":["النعناع","التفاح الأخضر","الليمون","حبوب التونكا","الأمبروكسان","إبرة الراعي","فانيليا مدغشقر","خشب الأرز من فرجينيا","خشب الأرز الأطلسي","نجيل الهند","طحلب البلوط"],"accords_en":["Vanilla","Aromatic","Green","Fresh Spicy","Fruity","Sweet"],"accords_ar":["فانيليا","أروماتك","أخضر","حار منعش","فاكهي","حلو"]},{"match_name_en":"Bleu de Chanel","item_name_en":"Bleu de Chanel","item_name_ar":"بلو دي شانيل","brand_name":"Chanel","description_en":"Bleu de Chanel by Chanel is a Woody Aromatic fragrance for men. Bleu de Chanel was launched in 2010. The nose behind this fragrance is Jacques Polge.","description_ar":"بلو دي شانيل من شانيل هو عطر خشبي أروماتك للرجال. تم إطلاق بلو دي شانيل في عام 2010. الأنف العطري وراء هذا العطر هو جاك بولج.","gender":1,"notes_en":["Grapefruit","Lemon","Mint","Pink Pepper","Ginger","Nutmeg","Jasmine","Iso E Super","Incense","Vetiver","Cedar","Sandalwood","Patchouli","Labdanum","White Musk"],"notes_ar":["الجريب فروت","الليمون","النعناع","الفلفل الوردي","الزنجبيل","جوزة الطيب","الياسمين","آيزو إي سوبر","البخور","نجيل الهند","خشب الأرز","خشب الصندل","الباتشولي","اللابدانوم","المسك الأبيض"],"accords_en":["Citrus","Woody","Warm Spicy","Aromatic","Amber","Smoky"],"accords_ar":["حمضي","خشبي","حار دافئ","أروماتك","عنبري","مدخن"]},{"match_name_en":"Eternity","item_name_en":"Eternity","item_name_ar":"إترنيتي للرجال","brand_name":"Calvin Klein","description_en":"Eternity For Men by Calvin Klein is an Aromatic Fougere fragrance for men. Eternity For Men was launched in 1990. The nose behind this fragrance is Carlos Benaim.","description_ar":"إترنيتي للرجال من كالفن كلاين هو عطر أروماتك فوچير للرجال. تم إطلاق إترنيتي للرجال في عام 1990. الأنف العطري وراء هذا العطر هو كارلوس بنيم.","gender":1,"notes_en":["Lavender","Lemon","Bergamot","Mandarin Orange","Sage","Juniper Berries","Basil","Geranium","Coriander","Jasmine","Lily-of-the-Valley","Orange Blossom","Sandalwood","Vetiver","Musk","Brazilian Rosewood","Amber"],"notes_ar":["الخزامى (اللافندر)","الليمون","البرغموت","اليوسفي","المريمية","توت العرعر","الريحان","إبرة الراعي","الكزبرة","الياسمين","زنبق الوادي","زهر البرتقال","خشب الصندل","نجيل الهند","المسك","خشب الورد البرازيلي","العنبر"],"accords_en":["Aromatic","Citrus","Fresh Spicy","Floral","Woody","Herbal"],"accords_ar":["أروماتك","حمضي","حار منعش","زهري","خشبي","عشبي"]},{"match_name_en":"Yara Candy","item_name_en":"Yara Candy","item_name_ar":"يارا كاندي","brand_name":"Sora","description_en":"Yara Candy by Sora is a Floral Fruity Gourmand fragrance for women. Yara Candy is known for its sweet, captivating candied profile.","description_ar":"يارا كاندي من سورا هو عطر زهري فاكهي غورماند للنساء. يشتهر يارا كاندي بتركيبته الحلوة والجذابة الغنية بالحلويات.","gender":2,"notes_en":["Candied Fruits","Tangerine","Black Currant","Strawberry","Vanilla Blossom","Caramel","Vanilla","Musk","Sandalwood"],"notes_ar":["الفواكه المسكرة","اليوسفي","الكشمش الأسود","الفراولة","زهر الفانيليا","الكراميل","الفانيليا","المسك","خشب الصندل"],"accords_en":["Sweet","Fruity","Vanilla","Caramel","Musky","Citrus"],"accords_ar":["حلو","فاكهي","فانيليا","كراميل","مسكي","حمضي"]},{"match_name_en":"Scandal","item_name_en":"Scandal","item_name_ar":"سكاندال","brand_name":"Jean Paul Gaultier","description_en":"Scandal by Jean Paul Gaultier is a Chypre Floral fragrance for women. Scandal was launched in 2017. Created by Daphné Bugey, Fabrice Pellegrin and Christophe Raynaud.","description_ar":"سكاندال من جان بول غوتييه هو عطر تشيبر زهري للنساء. تم إطلاق سكاندال في عام 2017. تم ابتكاره بواسطة دافني بوجي، فابريس بيليجرين وكريستوف رينو.","gender":2,"notes_en":["Blood Orange","Mandarin Orange","Honey","Gardenia","Orange Blossom","Jasmine","Peach","Beeswax","Caramel","Patchouli","Licorice"],"notes_ar":["البرتقال الأحمر","اليوسفي","العسل","الغاردينيا","زهر البرتقال","الياسمين","الخوخ","شمع العسل","الكراميل","الباتشولي","العرقسوس"],"accords_en":["Honey","Sweet","White Floral","Citrus","Caramel","Patchouli"],"accords_ar":["عسل","حلو","زهور بيضاء","حمضي","كراميل","باتشولي"]},{"match_name_en":"La vie est belle","item_name_en":"La vie est belle","item_name_ar":"لا في إي بيل","brand_name":"Lancome","description_en":"La Vie Est Belle by Lancôme is a Floral Fruity Gourmand fragrance for women. La Vie Est Belle was launched in 2012. Created by Olivier Polge, Dominique Ropion and Anne Flipo.","description_ar":"لا في إي بيل من لانكوم هو عطر زهري فاكهي غورماند للنساء. تم إطلاق لا في إي بيل في عام 2012. تم ابتكاره بواسطة أوليفييه بولج، دومينيك روبيون وآن فليبو.","gender":2,"notes_en":["Black Currant","Pear","Iris","Jasmine","Orange Blossom","Praline","Vanilla","Patchouli","Tonka Bean"],"notes_ar":["الكشمش الأسود","الكمثرى","السوسن","الياسمين","زهر البرتقال","الحلوى (البرالين)","الفانيليا","الباتشولي","حبوب التونكا"],"accords_en":["Sweet","Vanilla","Fruity","Powdery","Patchouli","White Floral"],"accords_ar":["حلو","فانيليا","فاكهي","بودري","باتشولي","زهور بيضاء"]},{"match_name_en":"Burberry Her","item_name_en":"Burberry Her","item_name_ar":"بربري هير","brand_name":"Burberry","description_en":"Burberry Her by Burberry is a Floral Fruity Gourmand fragrance for women. Burberry Her was launched in 2018. The nose behind this fragrance is Francis Kurkdjian.","description_ar":"بربري هير من بربري هو عطر زهري فاكهي غورماند للنساء. تم إطلاق بربري هير في عام 2018. الأنف العطري وراء هذا العطر هو فرانسيس كوركدجيان.","gender":2,"notes_en":["Strawberry","Raspberry","Blackberry","Sour Cherry","Black Currant","Mandarin Orange","Lemon","Violet","Jasmine","Musk","Vanilla","Cashmeran","Woody Notes","Oakmoss","Amber","Patchouli"],"notes_ar":["الفراولة","توت العليق","التوت الأسود","الكرز الحامض","الكشمش الأسود","اليوسفي","الليمون","البنفسج","الياسمين","المسك","الفانيليا","الكشميران","ملاحظات خشبية","طحلب البلوط","العنبر","الباتشولي"],"accords_en":["Fruity","Sweet","Woody","Musky","Powdery","Vanilla"],"accords_ar":["فاكهي","حلو","خشبي","مسكي","بودري","فانيليا"]},{"match_name_en":"Touch Of Pink","item_name_en":"Touch Of Pink","item_name_ar":"تاتش أوف بينك","brand_name":"Lacoste","description_en":"Touch of Pink by Lacoste Fragrances is a Floral Fruity fragrance for women. Touch of Pink was launched in 2004. The nose behind this fragrance is Domitille Michalon Bertier.","description_ar":"تاتش أوف بينك من لاكوست هو عطر زهري فاكهي للنساء. تم إطلاق تاتش أوف بينك في عام 2004. الأنف العطري وراء هذا العطر هي دوميتيل ميشالون بيرتيير.","gender":2,"notes_en":["Orange","Peach","Blood Orange","Coriander","Cardamom","Jasmine","Violet Leaf","Carrot Seeds","Vanilla","Musk","Sandalwood"],"notes_ar":["البرتقال","الخوخ","البرتقال الأحمر","الكزبرة","الحبهان (الهيل)","الياسمين","أوراق البنفسج","بذور الجزر","الفانيليا","المسك","خشب الصندل"],"accords_en":["Citrus","Powdery","Fruity","Musky","Vanilla","Warm Spicy"],"accords_ar":["حمضي","بودري","فاكهي","مسكي","فانيليا","حار دافئ"]},{"match_name_en":"Yum Boujee Marshmallow","item_name_en":"Yum Boujee Marshmallow","item_name_ar":"يم بوجي مارشميلو","brand_name":"Kayali","description_en":"Yum Boujee Marshmallow by Kayali is a sweet, gourmand fragrance focusing on luscious marshmallow and sugary accords. (Note: Representative profile based on the Kayali Yum line).","description_ar":"يم بوجي مارشميلو من خيالي هو عطر غورماند حلو يركز على المارشميلو اللذيذ والتركيبات السكرية.","gender":2,"notes_en":["Marshmallow","Strawberry","Whipped Cream","Vanilla Orchid","Jasmine","Vanilla","White Musk","Sugar"],"notes_ar":["الخطمي (المارشميلو)","الفراولة","الكريمة المخفوقة","أوركيد الفانيليا","الياسمين","الفانيليا","المسك الأبيض","السكر"],"accords_en":["Sweet","Vanilla","Powdery","Lactonic","Fruity","Musky"],"accords_ar":["حلو","فانيليا","بودري","لاكتوني (حليبي)","فاكهي","مسكي"]},{"match_name_en":"Cool Water","item_name_en":"Cool Water","item_name_ar":"كول ووتر","brand_name":"Davidoff","description_en":"Cool Water by Davidoff is a Floral Aquatic fragrance for women. Cool Water was launched in 1996. The nose behind this fragrance is Pierre Bourdon.","description_ar":"كول ووتر من دافيدوف هو عطر زهري مائي للنساء. تم إطلاق كول ووتر في عام 1996. الأنف العطري وراء هذا العطر هو بيير بوردون.","gender":2,"notes_en":["Melon","Lotus","Lemon","Pineapple","Quince","Calone","Lily","Black Currant","Water Lily","Lily-of-the-Valley","Jasmine","Honey","Hawthorn","Rose","Musk","Vetiver","Raspberry","Blackberry","Root","Peach","Sandalwood","Vanilla"],"notes_ar":["البطيخ","اللوتس","الليمون","الأناناس","السفرجل","الكالون","الزنبق","الكشمش الأسود","زنبق الماء","زنبق الوادي","الياسمين","العسل","الزعرور","الورد","المسك","نجيل الهند","توت العليق","التوت الأسود","الجذور","الخوخ","خشب الصندل","الفانيليا"],"accords_en":["Floral","Aquatic","Fruity","Fresh","Ozonic","Sweet"],"accords_ar":["زهري","مائي","فاكهي","منعش","أوزوني","حلو"]},{"match_name_en":"Madawy Gold","item_name_en":"Madawy Gold","item_name_ar":"مضاوي جولد إديشن","brand_name":"Arabian Oud","description_en":"Madawi Gold Edition by Arabian Oud is an Amber Floral fragrance for women and men. Madawi Gold is renowned for its luxurious fruity-floral character.","description_ar":"مضاوي جولد إديشن من العربية للعود هو عطر عنبري زهري للنساء والرجال. يشتهر مضاوي جولد بطابعه الفاكهي والزهري الفاخر.","gender":0,"notes_en":["Cardamom","Red Fruits","Pineapple","Jasmine","Tonka Bean","Vanilla","Patchouli","Musk"],"notes_ar":["الحبهان (الهيل)","الفواكه الحمراء","الأناناس","الياسمين","حبوب التونكا","الفانيليا","الباتشولي","المسك"],"accords_en":["Sweet","Fruity","Vanilla","Warm Spicy","White Floral","Musky"],"accords_ar":["حلو","فاكهي","فانيليا","حار دافئ","زهور بيضاء","مسكي"]},{"match_name_en":"Bianco Latte","item_name_en":"Bianco Latte","item_name_ar":"بيانكو لاتي","brand_name":"Giardini Di Toscana","description_en":"Bianco Latte by Giardini Di Toscana is an Amber Gourmand fragrance for women and men. Bianco Latte is a rich, comforting lactonic scent.","description_ar":"بيانكو لاتي من جيارديني دي توسكانا هو عطر عنبري غورماند للنساء والرجال. بيانكو لاتي هو عطر لاكتوني غني ومريح.","gender":0,"notes_en":["Caramel","Coumarin","Honey","Vanilla","White Musk"],"notes_ar":["الكراميل","الكومارين","العسل","الفانيليا","المسك الأبيض"],"accords_en":["Vanilla","Sweet","Caramel","Honey","Powdery","Musky"],"accords_ar":["فانيليا","حلو","كراميل","عسل","بودري","مسكي"]},{"match_name_en":"Baccarat Rouge 540","item_name_en":"Baccarat Rouge 540","item_name_ar":"باكارات روج 540","brand_name":"Maison Francis","description_en":"Baccarat Rouge 540 by Maison Francis Kurkdjian is an Amber Floral fragrance for women and men. Baccarat Rouge 540 was launched in 2015. The nose behind this fragrance is Francis Kurkdjian.","description_ar":"باكارات روج 540 من ميسون فرانسيس كوركدجيان هو عطر عنبري زهري للنساء والرجال. تم إطلاق باكارات روج 540 في عام 2015. الأنف العطري وراء هذا العطر هو فرانسيس كوركدجيان.","gender":0,"notes_en":["Saffron","Jasmine","Amberwood","Ambergris","Fir Resin","Cedar"],"notes_ar":["الزعفران","الياسمين","خشب العنبر","الآمبرغريس","راتنج التنوب","خشب الأرز"],"accords_en":["Woody","Amber","Warm Spicy","Fresh Spicy","Aromatic","Animalic"],"accords_ar":["خشبي","عنبري","حار دافئ","حار منعش","أروماتك","حيواني"]},{"match_name_en":"Khamrah Qahwa","item_name_en":"Khamra Qahwa","item_name_ar":"خمرة قهوة","brand_name":"Lattafa","description_en":"Khamrah Qahwa by Lattafa Perfumes is a fragrance for women and men. Khamrah Qahwa was launched in 2023.","description_ar":"خمرة قهوة من لطافة للعطور هو عطر للنساء والرجال. تم إطلاق خمرة قهوة في عام 2023.","gender":0,"notes_en":["Cinnamon","Cardamom","Ginger","Praline","Candied Fruits","White Flowers","Coffee","Vanilla","Tonka Bean","Benzoin","Musk"],"notes_ar":["القرفة","الحبهان (الهيل)","الزنجبيل","الحلوى (البرالين)","الفواكه المسكرة","الزهور البيضاء","القهوة","الفانيليا","حبوب التونكا","الجاوي","المسك"],"accords_en":["Warm Spicy","Sweet","Coffee","Vanilla","Cinnamon","Amber"],"accords_ar":["حار دافئ","حلو","قهوة","فانيليا","قرفة","عنبري"]},{"match_name_en":"God Of Fire","item_name_en":"God Of Fire","item_name_ar":"جود أوف فاير","brand_name":"Stéphane Humbert","description_en":"God of Fire by Stéphane Humbert Lucas 777 is an Amber Woody fragrance for women and men. God of Fire was launched in 2022. The nose behind this fragrance is Stéphane Humbert Lucas.","description_ar":"جود أوف فاير من ستيفان همبرت لوكاس 777 هو عطر عنبري خشبي للنساء والرجال. تم إطلاق جود أوف فاير في عام 2022. الأنف العطري وراء هذا العطر هو ستيفان همبرت لوكاس.","gender":0,"notes_en":["Mango","Lemon","Pink Berries","Ginger","Blue Coumarin","Jasmine","Woody Notes","Oud","Nagarmotha","Musk","Amber"],"notes_ar":["المانجو","الليمون","التوت الوردي","الزنجبيل","الكومارين الأزرق","الياسمين","ملاحظات خشبية","العود","السيبرول (الناجارموثا)","المسك","العنبر"],"accords_en":["Fruity","Tropical","Sweet","Woody","Citrus","Fresh"],"accords_ar":["فاكهي","استوائي","حلو","خشبي","حمضي","منعش"]},{"match_name_en":"Tuscan Leather","item_name_en":"Tuscan Leather","item_name_ar":"توسكان ليذر","brand_name":"Tom Ford","description_en":"Tuscan Leather by Tom Ford is a Leather fragrance for women and men. Tuscan Leather was launched in 2007. The nose behind this fragrance is Harry Fremont and Jacques Cavallier.","description_ar":"توسكان ليذر من توم فورد هو عطر جلود للنساء والرجال. تم إطلاق توسكان ليذر في عام 2007. الأنف العطري وراء هذا العطر هما هاري فريمونت وجاك كافالييه.","gender":0,"notes_en":["Raspberry","Saffron","Thyme","Olibanum","Jasmine","Leather","Suede","Woody Notes","Amber"],"notes_ar":["توت العليق","الزعفران","الزعتر","اللبان","الياسمين","الجلود","جلد الغزال (الشمواه)","ملاحظات خشبية","العنبر"],"accords_en":["Leather","Fruity","Animalic","Sweet","Amber","Smoky"],"accords_ar":["جلود","فاكهي","حيواني","حلو","عنبري","مدخن"]},{"match_name_en":"Erba Pura","item_name_en":"Erba Pura","item_name_ar":"إيربا بورا","brand_name":"Xerjoff","description_en":"Erba Pura by Xerjoff is an Amber fragrance for women and men. Erba Pura was launched in 2019. Created by Christian Carbonnel and Laura Santander.","description_ar":"إيربا بورا من زيرجوف هو عطر عنبري للنساء والرجال. تم إطلاق إيربا بورا في عام 2019. تم ابتكاره بواسطة كريستيان كاربونيل ولورا سانتاندير.","gender":0,"notes_en":["Sicilian Orange","Calabrian Bergamot","Sicilian Lemon","Fruits","White Musk","Madagascar Vanilla","Amber"],"notes_ar":["البرتقال الصقلي","برغموت كالابريا","الليمون الصقلي","فواكه","المسك الأبيض","فانيليا مدغشقر","العنبر"],"accords_en":["Fruity","Citrus","Sweet","Musky","Powdery","Vanilla"],"accords_ar":["فاكهي","حمضي","حلو","مسكي","بودري","فانيليا"]},{"match_name_en":"BMW M 2025","item_name_en":"BMW M 2025","item_name_ar":"بي إم دبليو إم 2025","brand_name":"BMW","description_en":"BMW M (Representative Profile) is a dynamic Woody Aromatic fragrance for men, capturing the essence of luxury and adrenaline with leather and metallic notes.","description_ar":"بي إم دبليو إم (وصف تمثيلي) هو عطر خشبي أروماتك ديناميكي للرجال، يجسد جوهر الفخامة والأدرينالين مع نفحات الجلود والمعدن.","gender":1,"notes_en":["Lemon","Bergamot","Metallic Notes","Lavender","Violet Leaf","Black Pepper","Leather","Vetiver","Cedar","Musk"],"notes_ar":["الليمون","البرغموت","نوتات معدنية","الخزامى (اللافندر)","أوراق البنفسج","الفلفل الأسود","الجلود","نجيل الهند","خشب الأرز","المسك"],"accords_en":["Citrus","Leather","Metallic","Fresh Spicy","Woody","Aromatic"],"accords_ar":["حمضي","جلود","معدني","حار منعش","خشبي","أروماتك"]},{"match_name_en":"Don","item_name_en":"Don","item_name_ar":"دون","brand_name":"Xerjoff","description_en":"Don by Xerjoff is an Amber Fougere fragrance for women and men. Don was launched in 2013. The nose behind this fragrance is Chris Maurice.","description_ar":"دون من زيرجوف هو عطر عنبري فوچير للنساء والرجال. تم إطلاق دون في عام 2013. الأنف العطري وراء هذا العطر هو كريس موريس.","gender":0,"notes_en":["Gunpowder","Whiskey","Tobacco","Spun Sugar"],"notes_ar":["البارود","الويسكي","التبغ","غزل البنات (السكر المغزول)"],"accords_en":["Tobacco","Whiskey","Sweet","Smoky","Warm Spicy"],"accords_ar":["تبغ","ويسكي","حلو","مدخن","حار دافئ"]},{"match_name_en":"Rose Oud","item_name_en":"Rose Oud","item_name_ar":"روز عود","brand_name":"Kilian","description_en":"Rose Oud by By Kilian is an Amber Woody fragrance for women and men. Rose Oud was launched in 2010. The nose behind this fragrance is Calice Becker.","description_ar":"روز عود من كيليان هو عطر عنبري خشبي للنساء والرجال. تم إطلاق روز عود في عام 2010. الأنف العطري وراء هذا العطر هي كاليس بيكر.","gender":0,"notes_en":["Saffron","Cinnamon","Rose","Agarwood (Oud)","Guaiac Wood","Cedar"],"notes_ar":["الزعفران","القرفة","الورد","العود","خشب الغاياك","خشب الأرز"],"accords_en":["Rose","Oud","Warm Spicy","Woody","Floral","Leather"],"accords_ar":["ورد","عود","حار دافئ","خشبي","زهري","جلود"]},{"match_name_en":"Tobacco Vanille","item_name_en":"Tobacco Vanille","item_name_ar":"توباكو فانيليا","brand_name":"Tom Ford","description_en":"Tobacco Vanille by Tom Ford is an Amber Spicy fragrance for women and men. Tobacco Vanille was launched in 2007. The nose behind this fragrance is Olivier Gillotin.","description_ar":"توباكو فانيليا من توم فورد هو عطر عنبري حار للنساء والرجال. تم إطلاق توباكو فانيليا في عام 2007. الأنف العطري وراء هذا العطر هو أوليفييه جيلوتين.","gender":0,"notes_en":["Tobacco Leaf","Spicy Notes","Vanilla","Cacao","Tonka Bean","Tobacco Blossom","Dried Fruits","Woody Notes"],"notes_ar":["أوراق التبغ","نوتات حارة","الفانيليا","الكاكاو","حبوب التونكا","زهر التبغ","الفواكه المجففة","ملاحظات خشبية"],"accords_en":["Vanilla","Sweet","Tobacco","Warm Spicy","Fruity","Cacao"],"accords_ar":["فانيليا","حلو","تبغ","حار دافئ","فاكهي","كاكاو"]}]$perfume_catalog$::jsonb) as source (
  match_name_en text,
  item_name_en text,
  item_name_ar text,
  brand_name text,
  description_en text,
  description_ar text,
  gender integer,
  notes_en jsonb,
  notes_ar jsonb,
  accords_en jsonb,
  accords_ar jsonb
);

update public.items as item
set
  "categoryID" = 1,
  "subCategoryID" = null,
  gender = source.gender,
  "itemName" = source.item_name_ar,
  "itemNameEN" = source.item_name_en,
  "brandName" = source.brand_name,
  "itemDescription" = source.description_ar,
  "itemDescriptionEN" = source.description_en,
  notes = source.notes_ar,
  "notesEN" = source.notes_en,
  accords = source.accords_ar,
  "accordsEN" = source.accords_en
from perfume_import as source
where lower(trim(item."itemNameEN")) = lower(trim(source.match_name_en));

with missing_items as (
  select
    source.*,
    row_number() over (order by source.item_name_en) as row_number
  from perfume_import as source
  where not exists (
    select 1
    from public.items as item
    where lower(trim(item."itemNameEN")) = lower(trim(source.item_name_en))
  )
),
next_item_id as (
  select coalesce(max(id), 0)::bigint as maximum_id
  from public.items
)
insert into public.items (
  id,
  "categoryID",
  "subCategoryID",
  gender,
  "itemName",
  "itemNameEN",
  "brandName",
  "itemDescription",
  "itemDescriptionEN",
  notes,
  "notesEN",
  accords,
  "accordsEN",
  "isFeatured"
)
select
  next_item_id.maximum_id + missing_items.row_number,
  1,
  null,
  missing_items.gender,
  missing_items.item_name_ar,
  missing_items.item_name_en,
  missing_items.brand_name,
  missing_items.description_ar,
  missing_items.description_en,
  missing_items.notes_ar,
  missing_items.notes_en,
  missing_items.accords_ar,
  missing_items.accords_en,
  false
from missing_items
cross join next_item_id;

update public.item_properties as property
set
  price = case property.size
    when 10 then 80
    when 30 then 200
    when 50 then 450
    when 100 then 800
  end,
  "inStock" = true,
  "isDefault" = property.size = 10,
  "PropertyDescription" =
    source.item_name_ar || ' - ' || property.size || ' مل',
  "propertyDescriptionEN" =
    source.item_name_en || ' - ' || property.size || ' ml'
from public.items as item
join perfume_import as source
  on lower(trim(item."itemNameEN")) = lower(trim(source.item_name_en))
where property."itemID" = item.id
  and property.size in (10, 30, 50, 100);

with desired_properties (size, price) as (
  values
    (10, 80::double precision),
    (30, 200::double precision),
    (50, 450::double precision),
    (100, 800::double precision)
),
missing_properties as (
  select
    item.id as item_id,
    source.item_name_ar,
    source.item_name_en,
    desired.size,
    desired.price,
    row_number() over (order by item.id, desired.size) as row_number
  from public.items as item
  join perfume_import as source
    on lower(trim(item."itemNameEN")) = lower(trim(source.item_name_en))
  cross join desired_properties as desired
  where not exists (
    select 1
    from public.item_properties as property
    where property."itemID" = item.id
      and property.size = desired.size
  )
),
next_property_id as (
  select coalesce(max(id), 0)::bigint as maximum_id
  from public.item_properties
)
insert into public.item_properties (
  id,
  "itemID",
  size,
  image,
  price,
  "inStock",
  "PropertyDescription",
  "isDefault",
  "propertyDescriptionEN"
)
select
  next_property_id.maximum_id + missing_properties.row_number,
  missing_properties.item_id,
  missing_properties.size,
  '',
  missing_properties.price,
  true,
  missing_properties.item_name_ar || ' - ' || missing_properties.size || ' مل',
  missing_properties.size = 10,
  missing_properties.item_name_en || ' - ' || missing_properties.size || ' ml'
from missing_properties
cross join next_property_id;

do $verification$
begin
  if (
    select count(*)
    from public.items as item
    join perfume_import as source
      on lower(trim(item."itemNameEN")) = lower(trim(source.item_name_en))
  ) <> 32 then
    raise exception 'Perfume import did not produce exactly 32 matching items.';
  end if;

  if exists (
    select 1
    from public.items as item
    join perfume_import as source
      on lower(trim(item."itemNameEN")) = lower(trim(source.item_name_en))
    cross join (values (10), (30), (50), (100)) as desired(size)
    where not exists (
      select 1
      from public.item_properties as property
      where property."itemID" = item.id
        and property.size = desired.size
        and property.price = case desired.size
          when 10 then 80
          when 30 then 200
          when 50 then 450
          when 100 then 800
        end
    )
  ) then
    raise exception 'One or more perfume sizes or prices failed validation.';
  end if;
end
$verification$;

drop table perfume_import;
