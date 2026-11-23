# Menu photography
The bundled JPG files are representative stock photographs, not photos taken of
this shop's actual products. Similar drinks/sandwiches may share a photograph.
They are downloaded once into public/images/menu and served locally.
Source: Pexels. License: https://www.pexels.com/license/

- espresso.jpg: https://www.pexels.com/photo/coffee-beans-and-a-cup-of-coffee-on-a-wooden-table-8937417/
- latte.jpg: https://www.pexels.com/photo/cup-of-delicious-coffee-18163776/
- iced-coffee.jpg: https://www.pexels.com/photo/glass-of-iced-coffee-on-cafe-counter-36447675/
- iced-latte.jpg: https://www.pexels.com/photo/ice-cold-coffee-in-a-clear-drinking-glass-10027268/
- matcha.jpg: https://www.pexels.com/photo/close-up-photo-of-matcha-latte-on-a-ceramic-cup-4552171/
- iced-matcha.jpg: https://www.pexels.com/photo/refreshing-matcha-latte-with-bamboo-whisk-32300846/
- chocolate.jpg: https://www.pexels.com/photo/close-up-photo-of-a-cup-of-hot-cocoa-11894048/
- croissant.jpg: https://www.pexels.com/photo/close-up-photo-of-croissant-3892469/
- muffin.jpg: https://www.pexels.com/photo/ready-to-eat-muffins-with-bilberries-17738646/
- cheesecake.jpg: https://www.pexels.com/photo/a-slice-of-cheesecake-with-strawberries-on-top-17324803/
- sandwich.jpg: https://www.pexels.com/photo/sandwich-on-plate-26936274/
- ham-sandwich.jpg: https://www.pexels.com/photo/sandwich-on-plate-20206168/

## Sample data
php artisan db:seed --class=DemoShopSeeder
Creates missing menu items, example ingredients/opening movements, and tables.
It preserves existing prices, stock, categories, image selections and accounts.
No sales, orders or reservations are invented. Review sample quantities/capacities
before using them for a real shop. Ingredient recipes remain configured by admin.
DatabaseSeeder calls AdminSeeder and DemoShopSeeder for a fresh install.