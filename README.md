# Arcturus Catalog to Plus Catalog migration
This script will convert your catalog from Arcturus MS catalog to Plus emulator structure.

It has been tested migrating a catalog from Arcturus MS to Plus++ emulator.

This script was mostly written by Chat-GPT 🙏 and is purely released as there's no good public catalog for Plus emulator available, so in-case you're looking to start a hotel with Plus emulator, you might find this handy.

**Important** 
Do not forgert to backup your database before running this script, by using it you achknowledge it's on your own responsibility.

**How to use**
When you want to migrate your Arcturus MS catalog to Plus structure, you must open the file and at the very top you'll see:
``SET @source_db = 'your_arcturus_db';`` & ``SET @destination_db = 'your_plus_db';``

Once those two has been set, you can freely run the script and it'll do the job for you.

**Tables it will migrate**
- catalog_pages -> catalog_pages
- catalog_items -> catalog_items
- catalog_clothing -> catalog_clothing
- items_base -> furniture

To help making sure most data is correct, it will backup the tables it migrate and from that update interaction types based of the default plus catalog that came with your emulator, you can at any time reference the backed up tables in-case something is wrong.

**Contributions**
Contributions is highly appreciated, in-case you think you can improve the script, feel free to make a pull request, describing what your contributions does and why it'd be benficial. 
