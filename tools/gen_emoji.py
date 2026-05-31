#!/usr/bin/env python3
"""Generates Sources/Services/Emoji.swift from the researched food->emoji data.

Dedupes by keyword (first occurrence wins, in category order: produce, proteins,
dairy/bakery/grains, pantry, snacks/drinks/non-food). The matcher (in Swift)
checks "complex" keywords (containing a space/hyphen) by substring first, then
single alpha keywords by word-prefix, each sorted longest-first so specific
terms win (e.g. "peach" before "pea", "eggplant" before "egg")."""
import re, sys

RAW = r"""
# --- produce ---
("apple", "🍎"),("green apple", "🍏"),("pear", "🍐"),("quince", "🍐"),("crabapple", "🍎"),
("orange", "🍊"),("mandarin", "🍊"),("clementine", "🍊"),("satsuma", "🍊"),("tangerine", "🍊"),
("lemon", "🍋"),("lime", "🍋"),("grapefruit", "🍊"),("kumquat", "🍊"),("pomelo", "🍊"),("yuzu", "🍋"),
("banana", "🍌"),("plantain", "🍌"),("strawberr", "🍓"),("blueberr", "🫐"),("raspberr", "🍓"),
("blackberr", "🫐"),("cranberr", "🍒"),("gooseberr", "🍏"),("elderberr", "🫐"),("mulberr", "🫐"),
("redcurrant", "🍒"),("blackcurrant", "🫐"),("currant", "🫐"),("grape", "🍇"),("cherr", "🍒"),
("peach", "🍑"),("nectarine", "🍑"),("apricot", "🍑"),("plum", "🍑"),("greengage", "🍏"),("damson", "🍇"),
("melon", "🍈"),("cantaloupe", "🍈"),("honeydew", "🍈"),("watermelon", "🍉"),("galia", "🍈"),
("mango", "🥭"),("pineapple", "🍍"),("kiwi", "🥝"),("papaya", "🥭"),("pawpaw", "🥭"),("guava", "🍐"),
("lychee", "🍑"),("rambutan", "🍑"),("longan", "🍑"),("passionfruit", "🥝"),("passion fruit", "🥝"),
("dragonfruit", "🍈"),("dragon fruit", "🍈"),("persimmon", "🍊"),("sharon fruit", "🍊"),
("pomegranate", "🍎"),("fig", "🍇"),("date", "🥭"),("coconut", "🥥"),("starfruit", "🍏"),("carambola", "🍏"),
("jackfruit", "🥭"),("durian", "🥭"),("mangosteen", "🍇"),("tamarind", "🥭"),("physalis", "🍊"),
("avocado", "🥑"),("olive", "🫒"),("tomato", "🍅"),("cherry tomato", "🍅"),("plum tomato", "🍅"),
("beef tomato", "🍅"),("tomatillo", "🍅"),("potato", "🥔"),("sweet potato", "🥔"),("yam", "🥔"),
("cassava", "🥔"),("taro", "🥔"),("carrot", "🥕"),("parsnip", "🥕"),("turnip", "🥔"),("swede", "🥔"),
("rutabaga", "🥔"),("beetroot", "🥔"),("beet", "🥔"),("radish", "🥕"),("daikon", "🥕"),("celeriac", "🥔"),
("ginger", "🥔"),("turmeric", "🥕"),("galangal", "🥔"),("horseradish", "🥕"),("kohlrabi", "🥬"),
("salsify", "🥕"),("jicama", "🥔"),("onion", "🧅"),("red onion", "🧅"),("shallot", "🧅"),("garlic", "🧄"),
("leek", "🧅"),("spring onion", "🧅"),("scallion", "🧅"),("chive", "🌿"),("pak choi", "🥬"),("bok choy", "🥬"),
("broccoli", "🥦"),("broccolini", "🥦"),("tenderstem", "🥦"),("cauliflower", "🥦"),("romanesco", "🥦"),
("cabbage", "🥬"),("red cabbage", "🥬"),("savoy", "🥬"),("kale", "🥬"),("cavolo nero", "🥬"),
("brussels sprout", "🥬"),("sprout", "🥬"),("collard", "🥬"),("lettuce", "🥬"),("romaine", "🥬"),
("iceberg", "🥬"),("spinach", "🥬"),("rocket", "🥬"),("arugula", "🥬"),("watercress", "🥬"),("chard", "🥬"),
("endive", "🥬"),("chicory", "🥬"),("radicchio", "🥬"),("pumpkin", "🎃"),("squash", "🥒"),("butternut", "🥒"),
("courgette", "🥒"),("zucchini", "🥒"),("cucumber", "🥒"),("marrow", "🥒"),("gourd", "🥒"),
("aubergine", "🍆"),("eggplant", "🍆"),("bell pepper", "🫑"),("pepper", "🫑"),("capsicum", "🫑"),
("chilli", "🌶️"),("chili", "🌶️"),("jalapeno", "🌶️"),("habanero", "🌶️"),("serrano", "🌶️"),
("scotch bonnet", "🌶️"),("poblano", "🌶️"),("birds eye", "🌶️"),("ghost pepper", "🌶️"),("pea", "🫛"),
("petit pois", "🫛"),("green bean", "🫛"),("french bean", "🫛"),("runner bean", "🫛"),("edamame", "🫛"),
("broad bean", "🫘"),("fava", "🫘"),("mangetout", "🫛"),("snap pea", "🫛"),("snow pea", "🫛"),
("corn", "🌽"),("sweetcorn", "🌽"),("baby corn", "🌽"),("button mushroom", "🍄"),("mushroom", "🍄"),
("chestnut mushroom", "🍄"),("portobello", "🍄"),("shiitake", "🍄"),("oyster mushroom", "🍄"),
("porcini", "🍄"),("chanterelle", "🍄"),("enoki", "🍄"),("cremini", "🍄"),("morel", "🍄"),("basil", "🌿"),
("parsley", "🌿"),("coriander", "🌿"),("cilantro", "🌿"),("mint", "🌿"),("dill", "🌿"),("rosemary", "🌿"),
("thyme", "🌿"),("sage", "🌿"),("oregano", "🌿"),("tarragon", "🌿"),("bay leaf", "🌿"),("marjoram", "🌿"),
("fennel", "🥬"),("lemongrass", "🌿"),("sorrel", "🥬"),("artichoke", "🥬"),("asparagus", "🥬"),
("celery", "🥬"),("rhubarb", "🥬"),("samphire", "🥬"),("okra", "🥒"),("water chestnut", "🌰"),
("bamboo shoot", "🥬"),("bean sprout", "🥬"),("microgreen", "🥬"),("mizuna", "🥬"),("lambs lettuce", "🥬"),
# --- proteins ---
("beef", "🥩"),("steak", "🥩"),("sirloin", "🥩"),("ribeye", "🥩"),("rib eye", "🥩"),("rump", "🥩"),
("fillet steak", "🥩"),("filet mignon", "🥩"),("tenderloin", "🥩"),("t-bone", "🥩"),("porterhouse", "🥩"),
("flank", "🥩"),("brisket", "🍖"),("chuck", "🥩"),("topside", "🥩"),("silverside", "🥩"),
("braising steak", "🥩"),("stewing steak", "🥩"),("minced beef", "🥩"),("beef mince", "🥩"),
("ground beef", "🥩"),("mince", "🥩"),("oxtail", "🦴"),("short rib", "🍖"),("veal", "🥩"),("escalope", "🥩"),
("lamb", "🥩"),("lamb chop", "🥩"),("leg of lamb", "🍖"),("lamb shank", "🍖"),("lamb mince", "🥩"),
("mutton", "🥩"),("cutlet", "🥩"),("rack of lamb", "🍖"),("pork", "🥩"),("pork chop", "🥩"),
("pork belly", "🥓"),("pork loin", "🥩"),("pork shoulder", "🍖"),("pork mince", "🥩"),("spare rib", "🍖"),
("crackling", "🍖"),("gammon", "🍖"),("ham", "🍖"),("hock", "🍖"),("trotter", "🍖"),("bacon", "🥓"),
("pancetta", "🥓"),("lardon", "🥓"),("guanciale", "🥓"),("sausage", "🌭"),("chipolata", "🌭"),
("bratwurst", "🌭"),("frankfurter", "🌭"),("chorizo", "🌭"),("salami", "🌭"),("pepperoni", "🌭"),
("prosciutto", "🥓"),("parma ham", "🥓"),("bresaola", "🥩"),("mortadella", "🌭"),("kielbasa", "🌭"),
("black pudding", "🌭"),("haggis", "🌭"),("pastrami", "🍖"),("corned beef", "🥩"),("liver", "🍖"),
("kidney", "🍖"),("tripe", "🍖"),("chicken", "🍗"),("chicken breast", "🍗"),("chicken thigh", "🍗"),
("chicken wing", "🍗"),("chicken drumstick", "🍗"),("drumstick", "🍗"),("chicken leg", "🍗"),("poussin", "🍗"),
("turkey", "🍗"),("duck", "🍗"),("duck breast", "🍗"),("goose", "🍗"),("guinea fowl", "🍗"),("quail", "🍗"),
("pheasant", "🍗"),("partridge", "🍗"),("venison", "🥩"),("rabbit", "🍗"),("hare", "🍗"),("boar", "🥩"),
("salmon", "🐟"),("smoked salmon", "🐟"),("cod", "🐟"),("haddock", "🐟"),("tuna", "🐟"),("mackerel", "🐟"),
("sardine", "🐟"),("pilchard", "🐟"),("trout", "🐟"),("sea bass", "🐟"),("bass", "🐟"),("halibut", "🐟"),
("plaice", "🐟"),("sole", "🐟"),("herring", "🐟"),("kipper", "🐟"),("anchov", "🐟"),("swordfish", "🐟"),
("snapper", "🐠"),("pollock", "🐟"),("pollack", "🐟"),("hake", "🐟"),("monkfish", "🐟"),("tilapia", "🐠"),
("carp", "🐠"),("bream", "🐟"),("mullet", "🐟"),("turbot", "🐟"),("whiting", "🐟"),("coley", "🐟"),
("eel", "🐟"),("catfish", "🐟"),("perch", "🐠"),("pike", "🐟"),("sprat", "🐟"),("whitebait", "🐟"),
("pufferfish", "🐡"),("prawn", "🦐"),("shrimp", "🦐"),("king prawn", "🦐"),("scampi", "🦐"),
("langoustine", "🦐"),("crab", "🦀"),("crabmeat", "🦀"),("lobster", "🦞"),("crayfish", "🦞"),
("crawfish", "🦞"),("mussel", "🦪"),("clam", "🦪"),("oyster", "🦪"),("scallop", "🦪"),("cockle", "🦪"),
("whelk", "🦪"),("winkle", "🦪"),("squid", "🦑"),("calamari", "🦑"),("octopus", "🦑"),("cuttlefish", "🦑"),
("caviar", "🐟"),("roe", "🐟"),("fish finger", "🐟"),("fish fillet", "🐟"),("surimi", "🦀"),("egg", "🥚"),
("duck egg", "🥚"),("quail egg", "🥚"),("fried egg", "🍳"),("boiled egg", "🥚"),("scrambled egg", "🍳"),
("omelette", "🍳"),("egg white", "🥚"),("tofu", "🫘"),("tempeh", "🫘"),("seitan", "🫘"),("quorn", "🫘"),
("veggie sausage", "🌭"),("vegetarian sausage", "🌭"),("veggie burger", "🍔"),("soy mince", "🫘"),
("burger", "🍔"),("hamburger", "🍔"),("beefburger", "🍔"),("patty", "🍔"),("meatball", "🥩"),
("nugget", "🍗"),("schnitzel", "🥩"),("kebab", "🥩"),("deli meat", "🍖"),("cold cut", "🍖"),
("bone broth", "🦴"),("marrow bone", "🦴"),
# --- dairy / bakery / grains ---
("whole milk", "🥛"),("skimmed milk", "🥛"),("semi-skimmed", "🥛"),("milk", "🥛"),("oat milk", "🥛"),
("almond milk", "🥛"),("soy milk", "🥛"),("soya milk", "🥛"),("coconut milk", "🥛"),("rice milk", "🥛"),
("lactose-free milk", "🥛"),("evaporated milk", "🥛"),("condensed milk", "🥛"),("powdered milk", "🥛"),
("buttermilk", "🥛"),("kefir", "🥛"),("single cream", "🥛"),("double cream", "🥛"),("whipping cream", "🥛"),
("heavy cream", "🥛"),("sour cream", "🥛"),("soured cream", "🥛"),("clotted cream", "🥛"),
("creme fraiche", "🥛"),("cream", "🥛"),("custard", "🍮"),("greek yogurt", "🥛"),("natural yogurt", "🥛"),
("yogurt", "🥛"),("yoghurt", "🥛"),("cheddar", "🧀"),("mozzarella", "🧀"),("parmesan", "🧀"),
("parmigiano", "🧀"),("pecorino", "🧀"),("brie", "🧀"),("camembert", "🧀"),("feta", "🧀"),("gouda", "🧀"),
("edam", "🧀"),("emmental", "🧀"),("gruyere", "🧀"),("halloumi", "🧀"),("cottage cheese", "🧀"),
("cream cheese", "🧀"),("blue cheese", "🧀"),("gorgonzola", "🧀"),("stilton", "🧀"),("roquefort", "🧀"),
("ricotta", "🧀"),("mascarpone", "🧀"),("manchego", "🧀"),("provolone", "🧀"),("wensleydale", "🧀"),
("red leicester", "🧀"),("paneer", "🧀"),("cheese", "🧀"),("butter", "🧈"),("margarine", "🧈"),
("ghee", "🧈"),("ice cream", "🍦"),("gelato", "🍦"),("sorbet", "🍦"),("frozen yogurt", "🍦"),
("white bread", "🍞"),("wholemeal bread", "🍞"),("brown bread", "🍞"),("sourdough", "🍞"),("rye bread", "🍞"),
("granary bread", "🍞"),("seeded bread", "🍞"),("ciabatta", "🍞"),("focaccia", "🍞"),("brioche", "🍞"),
("bread", "🍞"),("loaf", "🍞"),("toast", "🍞"),("breadcrumb", "🍞"),("crouton", "🍞"),("roll", "🍞"),
("bun", "🍞"),("bap", "🍞"),("baguette", "🥖"),("french stick", "🥖"),("croissant", "🥐"),("pastr", "🥐"),
("danish", "🥐"),("pain au chocolat", "🥐"),("puff pastry", "🥐"),("filo", "🥐"),("shortcrust", "🥐"),
("pitta", "🫓"),("pita", "🫓"),("naan", "🫓"),("flatbread", "🫓"),("tortilla", "🫓"),("wrap", "🫓"),
("chapati", "🫓"),("roti", "🫓"),("lavash", "🫓"),("crumpet", "🥞"),("pancake", "🥞"),("pikelet", "🥞"),
("waffle", "🧇"),("pretzel", "🥨"),("bagel", "🥯"),("muffin", "🧁"),("cupcake", "🧁"),("cake", "🎂"),
("sponge cake", "🎂"),("cheesecake", "🍰"),("pie", "🥧"),("tart", "🥧"),("quiche", "🥧"),("donut", "🍩"),
("doughnut", "🍩"),("biscuit", "🍪"),("cookie", "🍪"),("digestive", "🍪"),("shortbread", "🍪"),
("cracker", "🍪"),("cornflake", "🥣"),("weetabix", "🥣"),("granola", "🥣"),("muesli", "🥣"),
("porridge", "🥣"),("oat", "🥣"),("bran", "🥣"),("shreddies", "🥣"),("shredded wheat", "🥣"),("cereal", "🥣"),
("cheerios", "🥣"),("rice krispies", "🥣"),("grits", "🥣"),("basmati", "🍚"),("jasmine rice", "🍚"),
("long grain", "🍚"),("arborio", "🍚"),("brown rice", "🍚"),("wild rice", "🍚"),("white rice", "🍚"),
("pudding rice", "🍚"),("risotto rice", "🍚"),("sushi rice", "🍚"),("rice", "🍚"),("rice ball", "🍙"),
("onigiri", "🍙"),("spaghetti", "🍝"),("penne", "🍝"),("fusilli", "🍝"),("macaroni", "🍝"),
("lasagne", "🍝"),("lasagna", "🍝"),("tagliatelle", "🍝"),("orzo", "🍝"),("gnocchi", "🍝"),("rigatoni", "🍝"),
("farfalle", "🍝"),("linguine", "🍝"),("conchiglie", "🍝"),("cannelloni", "🍝"),("ravioli", "🍝"),
("tortellini", "🍝"),("pasta", "🍝"),("couscous", "🍝"),("noodle", "🍜"),("egg noodle", "🍜"),
("rice noodle", "🍜"),("udon", "🍜"),("ramen", "🍜"),("soba", "🍜"),("vermicelli", "🍜"),("glass noodle", "🍜"),
("quinoa", "🥣"),("bulgur", "🥣"),("barley", "🥣"),("pearl barley", "🥣"),("polenta", "🥣"),("semolina", "🥣"),
("cornmeal", "🥣"),("buckwheat", "🥣"),("millet", "🥣"),("farro", "🥣"),("freekeh", "🥣"),("spelt", "🥣"),
("plain flour", "🥣"),("self-raising flour", "🥣"),("self raising flour", "🥣"),("bread flour", "🥣"),
("strong flour", "🥣"),("wholemeal flour", "🥣"),("flour", "🥣"),("cornflour", "🥣"),("cornstarch", "🥣"),
("yeast", "🥣"),("baking powder", "🥣"),("bicarbonate", "🥣"),("baking soda", "🥣"),("cocoa", "🥣"),
("sugar", "🍬"),("brown sugar", "🍬"),("caster sugar", "🍬"),("icing sugar", "🍬"),("granulated sugar", "🍬"),
("demerara", "🍬"),("muscovado", "🍬"),("salt", "🧂"),("sea salt", "🧂"),("table salt", "🧂"),
# --- pantry / flavour ---
("olive oil", "🫒"),("vegetable oil", "🥫"),("sunflower oil", "🥫"),("rapeseed oil", "🥫"),
("coconut oil", "🥫"),("sesame oil", "🥫"),("groundnut oil", "🥫"),("avocado oil", "🥫"),("corn oil", "🥫"),
("palm oil", "🥫"),("lard", "🥫"),("cooking oil", "🥫"),("vinegar", "🥫"),("balsamic", "🥫"),
("malt vinegar", "🥫"),("cider vinegar", "🥫"),("rice vinegar", "🥫"),("wine vinegar", "🥫"),
("ketchup", "🥫"),("mayonnaise", "🥫"),("mayo", "🥫"),("mustard", "🥫"),("dijon", "🥫"),("wholegrain", "🥫"),
("brown sauce", "🥫"),("tartare", "🥫"),("worcestershire", "🥫"),("soy sauce", "🥫"),("tamari", "🥫"),
("fish sauce", "🥫"),("oyster sauce", "🥫"),("hoisin", "🥫"),("teriyaki", "🥫"),("sriracha", "🥫"),
("tabasco", "🥫"),("hot sauce", "🥫"),("harissa", "🥫"),("pesto", "🥫"),("tahini", "🥫"),("salsa", "🥫"),
("guacamole", "🥫"),("hummus", "🥫"),("relish", "🥫"),("chutney", "🥫"),("pickle", "🥫"),("gherkin", "🥫"),
("piccalilli", "🥫"),("cranberry sauce", "🥫"),("mint sauce", "🥫"),("apple sauce", "🥫"),("aioli", "🥫"),
("ranch", "🥫"),("barbecue", "🥫"),("marinade", "🥫"),("dressing", "🥫"),("vinaigrette", "🥫"),
("chopped tomato", "🥫"),("tinned tomato", "🥫"),("passata", "🥫"),("tomato puree", "🥫"),
("tomato paste", "🥫"),("sun-dried", "🥫"),("baked bean", "🫘"),("caper", "🥫"),("sauerkraut", "🥫"),
("kimchi", "🥫"),("stock cube", "🥫"),("bouillon", "🥫"),("stock", "🥫"),("broth", "🥫"),("gravy", "🥫"),
("cumin", "🧂"),("paprika", "🧂"),("cinnamon", "🧂"),("nutmeg", "🧂"),("cardamom", "🧂"),("clove", "🧂"),
("star anise", "🧂"),("mustard seed", "🧂"),("curry powder", "🧂"),("garam masala", "🧂"),("allspice", "🧂"),
("mace", "🧂"),("saffron", "🧂"),("sumac", "🧂"),("zaatar", "🧂"),("fenugreek", "🧂"),("caraway", "🧂"),
("juniper", "🧂"),("peppercorn", "🧂"),("black pepper", "🧂"),("white pepper", "🧂"),("mixed herb", "🧂"),
("herbes", "🧂"),("vanilla", "🧂"),("seasoning", "🧂"),("chilli flake", "🌶️"),("chilli powder", "🌶️"),
("chili powder", "🌶️"),("cayenne", "🌶️"),("chipotle", "🌶️"),("garlic powder", "🧄"),
("garlic granule", "🧄"),("onion powder", "🧅"),("red lentil", "🫘"),("green lentil", "🫘"),
("brown lentil", "🫘"),("puy lentil", "🫘"),("lentil", "🫘"),("chickpea", "🫘"),("kidney bean", "🫘"),
("black bean", "🫘"),("cannellini", "🫘"),("butter bean", "🫘"),("haricot", "🫘"),("borlotti", "🫘"),
("pinto", "🫘"),("mung bean", "🫘"),("split pea", "🫘"),("marrowfat", "🫘"),("soya bean", "🫘"),
("bean", "🫘"),("pulse", "🫘"),("peanut butter", "🥜"),("peanut", "🥜"),("almond", "🥜"),("cashew", "🥜"),
("walnut", "🥜"),("pecan", "🥜"),("pistachio", "🥜"),("hazelnut", "🥜"),("macadamia", "🥜"),
("brazil nut", "🥜"),("pine nut", "🥜"),("nut butter", "🥜"),("almond butter", "🥜"),("mixed nut", "🥜"),
("chestnut", "🌰"),("sesame seed", "🥜"),("sunflower seed", "🥜"),("pumpkin seed", "🥜"),("chia seed", "🥜"),
("flaxseed", "🥜"),("linseed", "🥜"),("poppy seed", "🥜"),("hemp seed", "🥜"),("nigella", "🥜"),
("honey", "🍯"),("maple syrup", "🍯"),("golden syrup", "🍯"),("agave", "🍯"),("treacle", "🍯"),
("molasses", "🍯"),("syrup", "🍯"),("jam", "🍓"),("marmalade", "🍓"),("conserve", "🍓"),("compote", "🍓"),
("lemon curd", "🍓"),("nutella", "🍫"),("chocolate spread", "🍫"),("marmite", "🥫"),("yeast extract", "🥫"),
("bovril", "🥫"),("sweetener", "🍬"),
# --- snacks / drinks / frozen / prepared / non-food ---
("ready salted", "🍟"),("salt and vinegar", "🍟"),("cheese and onion", "🍟"),("crisp", "🍟"),
("tortilla chip", "🍟"),("pringle", "🍟"),("popcorn", "🍿"),("breadstick", "🥨"),("twiglet", "🥨"),
("poppadom", "🥨"),("chocolate", "🍫"),("milk chocolate", "🍫"),("dark chocolate", "🍫"),
("white chocolate", "🍫"),("choc bar", "🍫"),("chocolate button", "🍫"),("truffle", "🍫"),("praline", "🍫"),
("sweet", "🍬"),("candy", "🍬"),("gummy", "🍬"),("jelly bean", "🍬"),("wine gum", "🍬"),("fudge", "🍬"),
("toffee", "🍬"),("marshmallow", "🍬"),("liquorice", "🍬"),("humbug", "🍬"),("sherbet", "🍬"),
("lollipop", "🍭"),("cereal bar", "🍫"),("flapjack", "🍪"),("oatcake", "🍪"),("rich tea", "🍪"),
("wafer", "🍪"),("trail mix", "🥜"),("brownie", "🍰"),("trifle", "🍮"),("mousse", "🍮"),("jelly", "🍮"),
("pudding", "🍮"),("ice lolly", "🍧"),("coffee", "☕"),("instant coffee", "☕"),("ground coffee", "☕"),
("coffee bean", "☕"),("decaf", "☕"),("coffee pod", "☕"),("espresso", "☕"),("cappuccino", "☕"),
("latte", "☕"),("tea", "🍵"),("black tea", "🍵"),("green tea", "🍵"),("herbal tea", "🍵"),("fruit tea", "🍵"),
("chamomile", "🍵"),("peppermint tea", "🍵"),("earl grey", "🍵"),("loose tea", "🫖"),("teabag", "🫖"),
("hot chocolate", "☕"),("cola", "🥤"),("lemonade", "🥤"),("soda", "🥤"),("fizzy", "🥤"),("tonic", "🥤"),
("ginger ale", "🥤"),("energy drink", "🥤"),("orange juice", "🧃"),("apple juice", "🧃"),
("cranberry juice", "🧃"),("juice", "🧃"),("cordial", "🧃"),("smoothie", "🧋"),("milkshake", "🧋"),
("bubble tea", "🧋"),("sparkling water", "💧"),("still water", "💧"),("water", "💧"),("ice", "🧊"),
("lager", "🍺"),("ale", "🍺"),("stout", "🍺"),("beer", "🍺"),("cider", "🍺"),("red wine", "🍷"),
("white wine", "🍷"),("rose wine", "🍷"),("wine", "🍷"),("prosecco", "🥂"),("champagne", "🍾"),("vodka", "🥃"),
("gin", "🍸"),("whisky", "🥃"),("rum", "🥃"),("brandy", "🥃"),("tequila", "🥃"),("sherry", "🍷"),
("port", "🍷"),("liqueur", "🥃"),("cocktail", "🍹"),("frozen pizza", "🍕"),("pizza", "🍕"),
("fish finger", "🍱"),("chicken nugget", "🍱"),("oven chip", "🍟"),
("sandwich", "🥪"),("sub", "🥪"),("taco", "🌮"),("burrito", "🌯"),("tamale", "🫔"),
("gyro", "🥙"),("falafel", "🧆"),("ready meal", "🍱"),("bento", "🍱"),("curry", "🍛"),("stir fry", "🥘"),
("paella", "🥘"),("casserole", "🥘"),("pad thai", "🍜"),("pot noodle", "🍜"),("soup", "🍲"),("stew", "🍲"),
("hotpot", "🍲"),("sushi", "🍣"),("tempura", "🍤"),("dumpling", "🥟"),("gyoza", "🥟"),("dim sum", "🥟"),
# NB: no "frozen X" entries — "frozen peas" should resolve to peas via word-matching.
("samosa", "🥟"),("spring roll", "🥟"),("takeaway", "🥡"),("pasty", "🥧"),("sausage roll", "🥧"),
("washing up liquid", "🧴"),("dishwasher tablet", "🧴"),("laundry detergent", "🧴"),("fabric softener", "🧴"),
("bleach", "🧴"),("surface cleaner", "🧴"),("glass cleaner", "🧴"),("detergent", "🧴"),("bin bag", "🧹"),
("cling film", "🧻"),("foil", "🧻"),("baking paper", "🧻"),("sponge", "🧽"),("scourer", "🧽"),
("j-cloth", "🧽"),("rubber glove", "🧤"),("broom", "🧹"),("toilet roll", "🧻"),("kitchen roll", "🧻"),
("tissue", "🧻"),("kleenex", "🧻"),("napkin", "🧻"),("paper plate", "🧻"),("shampoo", "🧴"),
("conditioner", "🧴"),("shower gel", "🧴"),("soap", "🧼"),("hand wash", "🧼"),("deodorant", "🧴"),
("toothpaste", "🪥"),("toothbrush", "🪥"),("mouthwash", "🧴"),("floss", "🪥"),("razor", "🪒"),
("shaving foam", "🪒"),("moisturiser", "🧴"),("sunscreen", "🧴"),("cotton wool", "🧴"),("cotton bud", "🧴"),
("sanitary", "🩹"),("tampon", "🩹"),("nappy", "🍼"),("diaper", "🍼"),("baby wipe", "🍼"),("formula", "🍼"),
("baby food", "🍼"),("dog food", "🐾"),("cat food", "🐾"),("cat litter", "🐾"),("pet treat", "🐾"),
("paracetamol", "💊"),("ibuprofen", "💊"),("plaster", "🩹"),("bandage", "🩹"),("vitamin", "💊"),
("supplement", "💊"),("cough syrup", "💊"),("antacid", "💊"),("painkiller", "💊"),("first aid", "🩺"),
("battery", "🔋"),("candle", "🕯️"),("lightbulb", "💡"),("matches", "🔥"),("flower", "💐"),
("charcoal", "🔥"),("firelighter", "🔥"),
# --- supplement: close gaps + correct weak semantic guesses from the 1000-item audit ---
("mange tout", "🫛"),("lollo", "🥬"),("dandelion", "🥬"),("whitecurrant", "🫐"),
("loganberr", "🍓"),("cloudberr", "🫐"),("boysenberr", "🫐"),("medlar", "🍐"),("loquat", "🍑"),
("soursop", "🥭"),("cherimoya", "🥭"),("breadfruit", "🥭"),("tamarillo", "🍅"),
("heart", "🍖"),("nduja", "🌭"),("coppa", "🥓"),("spam", "🥫"),("suet", "🥩"),("goat", "🥩"),
("skyr", "🥛"),("quark", "🥛"),("smetana", "🥛"),("fromage", "🥛"),("velveeta", "🧀"),
("burrata", "🧀"),("gloucester", "🧀"),("grana", "🧀"),("comte", "🧀"),("havarti", "🧀"),
("taleggio", "🧀"),("monterey", "🧀"),("babybel", "🧀"),("fontina", "🧀"),
("mahi", "🐟"),("pangasius", "🐟"),("tarama", "🐟"),("skate", "🐟"),("ray wing", "🐟"),
("gurnard", "🐟"),("john dory", "🐟"),("dory", "🐟"),("brill", "🐟"),("megrim", "🐟"),
("coalfish", "🐟"),("ling", "🐟"),("cusk", "🐟"),("amberjack", "🐟"),("pompano", "🐟"),
("wahoo", "🐟"),("whitefish", "🐟"),("yellowtail", "🐟"),("bonito", "🐟"),("urchin", "🦪"),
("seaweed", "🍙"),("nori", "🍙"),
("grissini", "🥨"),("panko", "🍞"),("eclair", "🍩"),("teff", "🥣"),("sorghum", "🥣"),
("amaranth", "🥣"),("tapioca", "🥣"),("scone", "🥐"),("gateau", "🎂"),
("cholula", "🥫"),("worcester", "🥫"),("ras el hanout", "🧂"),
("biscoff", "🍪"),("hobnob", "🍪"),("horlicks", "🥛"),("hash brown", "🥔"),
("hot dog", "🌭"),("enchilada", "🌯"),("fajita", "🌯"),
("raisin", "🍇"),("sultana", "🍇"),("licorice", "🍬"),("caramel", "🍬"),("sprinkle", "🍬"),
"""

# Corrections to a few researched entries.
FIX = {"dip": None}  # drop: bad mapping + too-generic 3-letter keyword

pairs = re.findall(r'\("([^"]+)",\s*"([^"]+)"\)', RAW)
seen, table = set(), []
for kw, emoji in pairs:
    kw = kw.strip().lower()
    if kw in FIX:
        if FIX[kw] is None:
            continue
        emoji = FIX[kw]
    if kw in seen:
        continue
    seen.add(kw)
    table.append((kw, emoji))

lines = ",\n".join(f'        ("{kw}", "{e}")' for kw, e in table)
swift = '''import Foundation

// GENERATED by tools/gen_emoji.py — do not hand-edit; edit the data there and re-run.
// Curated keyword→emoji table (~%d entries) spanning produce, proteins, dairy,
// bakery, grains, pantry, drinks, snacks, frozen, prepared dishes and
// household/toiletry/baby/pet/health goods.
// `match` returns nil when nothing applies; Emoji.forName then tries the semantic
// fallback (SemanticEmoji) and finally a default glyph.
enum EmojiTable {
    static let entries: [(String, String)] = [
%s,
    ]

    // Keywords with a space or hyphen are matched as substrings (more specific,
    // checked first); plain single words match when a word in the name starts
    // with them. Each group is sorted longest-first so specific terms win
    // (e.g. "peach" before "pea", "eggplant" before "egg", "hamburger" before "ham").
    private static let complexKeywords: [(String, String)] =
        entries.filter { $0.0.contains(where: { !$0.isLetter }) }
               .sorted { $0.0.count > $1.0.count }
    private static let simpleKeywords: [(String, String)] =
        entries.filter { !$0.0.contains(where: { !$0.isLetter }) }
               .sorted { $0.0.count > $1.0.count }

    /// Curated match, or nil if nothing in the table applies.
    static func match(_ name: String) -> String? {
        let lower = name.lowercased()
        for (keyword, glyph) in complexKeywords where lower.contains(keyword) {
            return glyph
        }
        let words = lower.split { !$0.isLetter }.map(String.init)
        for (keyword, glyph) in simpleKeywords
        where words.contains(where: { $0.hasPrefix(keyword) }) {
            return glyph
        }
        return nil
    }
}
''' % (len(table), lines)

out = sys.argv[1] if len(sys.argv) > 1 else "Sources/Services/EmojiTable.swift"
with open(out, "w") as f:
    f.write(swift)
print(f"wrote {out} with {len(table)} entries")
