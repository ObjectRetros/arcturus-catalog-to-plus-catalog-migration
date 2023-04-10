-- Set the source and destination database names
SET @source_db = 'your_arcturus_db';
SET @destination_db = 'your_plus_db';

-- Create a backup of the destination table
SET @timestamp = UNIX_TIMESTAMP();
SET @backup_table = CONCAT('catalog_pages_backup_', @timestamp);

SET @clone_sql = CONCAT('CREATE TABLE ', @destination_db, '.', @backup_table, ' LIKE ', @destination_db, '.catalog_pages;');
PREPARE clone_stmt FROM @clone_sql;
EXECUTE clone_stmt;
DEALLOCATE PREPARE clone_stmt;

SET @copy_data_sql = CONCAT('INSERT INTO ', @destination_db, '.', @backup_table, ' SELECT * FROM ', @destination_db, '.catalog_pages;');
PREPARE copy_data_stmt FROM @copy_data_sql;
EXECUTE copy_data_stmt;
DEALLOCATE PREPARE copy_data_stmt;

SET @truncate_sql = CONCAT('TRUNCATE TABLE ', @destination_db, '.catalog_pages;');
PREPARE truncate_stmt FROM @truncate_sql;
EXECUTE truncate_stmt;
DEALLOCATE PREPARE truncate_stmt;

SET @sql = CONCAT('
    INSERT INTO ', @destination_db, '.catalog_pages
        (
            id, parent_id, caption, icon_image, visible, enabled, min_rank, min_vip,
            order_num, page_link, page_layout, page_strings_1, page_strings_2
        )
    SELECT
        id,
        parent_id,
        caption,
        icon_image,
        visible,
        enabled,
        min_rank,
        min_rank AS min_vip,
        order_num,
        caption AS page_link,
        page_layout,
        CONCAT(COALESCE(page_headline, ""), "|", COALESCE(page_teaser, "")) AS page_strings_1,
        CONCAT(COALESCE(page_text1, ""), "|", COALESCE(page_text2, ""), "|", COALESCE(page_text_teaser, ""), "|", COALESCE(page_text_details, "")) AS page_strings_2
    FROM
        ', @source_db, '.catalog_pages;
');

-- Execute the dynamic SQL statement
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- items_base migration
-- Clone the destination table with a timestamp
SET @timestamp = UNIX_TIMESTAMP();
SET @backup_table = CONCAT('furniture_backup_', @timestamp);

-- Clone the structure
SET @clone_sql = CONCAT('CREATE TABLE ', @destination_db, '.', @backup_table, ' LIKE ', @destination_db, '.furniture;');
PREPARE clone_stmt FROM @clone_sql;
EXECUTE clone_stmt;
DEALLOCATE PREPARE clone_stmt;

-- Clone the data
SET @copy_data_sql = CONCAT('INSERT INTO ', @destination_db, '.', @backup_table, ' SELECT * FROM ', @destination_db, '.furniture;');
PREPARE copy_data_stmt FROM @copy_data_sql;
EXECUTE copy_data_stmt;
DEALLOCATE PREPARE copy_data_stmt;

SET @truncate_sql = CONCAT('TRUNCATE TABLE ', @destination_db, '.furniture;');
PREPARE truncate_stmt FROM @truncate_sql;
EXECUTE truncate_stmt;
DEALLOCATE PREPARE truncate_stmt;

SET @alter_sql = CONCAT('ALTER TABLE ', @destination_db, '.furniture MODIFY COLUMN interaction_type VARCHAR(255);');
PREPARE alter_stmt FROM @alter_sql;
EXECUTE alter_stmt;
DEALLOCATE PREPARE alter_stmt;

SET @alter_sql = CONCAT('ALTER TABLE ', @destination_db, '.furniture MODIFY COLUMN item_name VARCHAR(255);');
PREPARE alter_stmt FROM @alter_sql;
EXECUTE alter_stmt;
DEALLOCATE PREPARE alter_stmt;

-- Migrate data
SET @type_case = '
    CASE
        WHEN type = "s" THEN "s"
        WHEN type = "i" THEN "i"
        WHEN type = "e" THEN "e"
        WHEN type = "h" THEN "h"
        WHEN type = "v" THEN "v"
        WHEN type = "b" THEN "b"
        WHEN type = "p" THEN "p"
        ELSE "s"
    END
';

SET @migrate_sql = CONCAT('
    INSERT INTO ', @destination_db, '.furniture
        (
            id, sprite_id, item_name, type, width, length, stack_height, can_stack,
            can_sit, is_walkable, allow_gift, allow_trade, allow_recycle,
            allow_marketplace_sell, allow_inventory_stack, interaction_type,
            interaction_modes_count, vending_ids, height_adjustable,
            effect_id
        )
    SELECT
        id, sprite_id, item_name,
        ', @type_case, ' AS type,
        width, length, stack_height,
        IF(allow_stack = 1, "1", "0") AS can_stack,
        IF(allow_sit = 1, "1", "0") AS can_sit,
        IF(allow_walk = 1, "1", "0") AS is_walkable,
        IF(allow_gift = 1, "1", "0") AS allow_gift,
        IF(allow_trade = 1, "1", "0") AS allow_trade,
        IF(allow_recycle = 1, "1", "0") AS allow_recycle,
        IF(allow_marketplace_sell = 1, "1", "0") AS allow_marketplace_sell,
        IF(allow_inventory_stack = 1, "1", "0") AS allow_inventory_stack,
        interaction_type, interaction_modes_count,
        IF(CAST(vending_ids AS SIGNED) IS NULL, 0, vending_ids) AS vending_ids,
        IF(CAST(multiheight AS SIGNED) IS NULL, 0, multiheight) AS height_adjustable,
        IF(CAST(effect_id_male AS SIGNED) IS NULL, 0, effect_id_male) AS effect_id
    FROM
        ', @source_db, '.items_base;
');
PREPARE migrate_stmt FROM @migrate_sql;
EXECUTE migrate_stmt;
DEALLOCATE PREPARE migrate_stmt;


-- Update the matching columns in the destination table based on the cloned table
SET @update_sql = CONCAT('
    UPDATE
        ', @destination_db, '.furniture AS f
    INNER JOIN
        ', @destination_db, '.', @backup_table, ' AS fb
    ON
        f.item_name = fb.item_name
    SET
        f.interaction_type = fb.interaction_type,
        f.behaviour_data = fb.behaviour_data,
        f.is_rare = fb.is_rare,
        f.wired_id = fb.wired_id;
');
PREPARE update_stmt FROM @update_sql;
EXECUTE update_stmt;
DEALLOCATE PREPARE update_stmt;

-- Create a backup of the destination table
SET @timestamp = UNIX_TIMESTAMP();
SET @backup_table = CONCAT('catalog_items_backup_', @timestamp);

SET @clone_sql = CONCAT('CREATE TABLE ', @destination_db, '.', @backup_table, ' LIKE ', @destination_db, '.catalog_items;');
PREPARE clone_stmt FROM @clone_sql;
EXECUTE clone_stmt;
DEALLOCATE PREPARE clone_stmt;

SET @copy_data_sql = CONCAT('INSERT INTO ', @destination_db, '.', @backup_table, ' SELECT * FROM ', @destination_db, '.catalog_items;');
PREPARE copy_data_stmt FROM @copy_data_sql;
EXECUTE copy_data_stmt;
DEALLOCATE PREPARE copy_data_stmt;

SET @truncate_sql = CONCAT('TRUNCATE TABLE ', @destination_db, '.catalog_items;');
PREPARE truncate_stmt FROM @truncate_sql;
EXECUTE truncate_stmt;
DEALLOCATE PREPARE truncate_stmt;

SET @alter_sql = CONCAT('ALTER TABLE ', @destination_db, '.catalog_items MODIFY COLUMN item_id VARCHAR(255);');
PREPARE alter_stmt FROM @alter_sql;
EXECUTE alter_stmt;
DEALLOCATE PREPARE alter_stmt;

-- Migrate data
SET @migrate_sql = CONCAT('
    INSERT INTO ', @destination_db, '.catalog_items
        (
            id, page_id, item_id, catalog_name, cost_credits, cost_pixels, cost_diamonds,
            amount, limited_sells, limited_stack, offer_active, extradata, offer_id
        )
    SELECT
        id, page_id, item_ids, catalog_name, cost_credits,
        IF(points_type = 0 AND cost_points > 0, cost_points, 0) AS cost_pixels,
        IF(points_type = 5 AND cost_points > 0 OR (cost_points > 0 AND points_type != 0), cost_points, 0) AS cost_diamonds,
        amount, limited_sells, limited_stack, have_offer, extradata, offer_id
    FROM
        ', @source_db, '.catalog_items;
');

PREPARE migrate_stmt FROM @migrate_sql;
EXECUTE migrate_stmt;
DEALLOCATE PREPARE migrate_stmt;

SET @timestamp = UNIX_TIMESTAMP();
SET @backup_table = CONCAT('catalog_clothing_backup_', @timestamp);

SET @clone_sql = CONCAT('CREATE TABLE ', @destination_db, '.', @backup_table, ' LIKE ', @destination_db, '.catalog_clothing;');
PREPARE clone_stmt FROM @clone_sql;
EXECUTE clone_stmt;
DEALLOCATE PREPARE clone_stmt;

SET @copy_data_sql = CONCAT('INSERT INTO ', @destination_db, '.', @backup_table, ' SELECT * FROM ', @destination_db, '.catalog_clothing;');
PREPARE copy_data_stmt FROM @copy_data_sql;
EXECUTE copy_data_stmt;
DEALLOCATE PREPARE copy_data_stmt;

SET @truncate_sql = CONCAT('TRUNCATE TABLE ', @destination_db, '.catalog_clothing;');
PREPARE truncate_stmt FROM @truncate_sql;
EXECUTE truncate_stmt;
DEALLOCATE PREPARE truncate_stmt;

-- Migrate data
SET @migrate_sql = CONCAT('
    INSERT INTO ', @destination_db, '.catalog_clothing
        (
            id, clothing_name
        )
    SELECT
        id, name
    FROM
        ', @source_db, '.catalog_clothing;
');

PREPARE migrate_stmt FROM @migrate_sql;
EXECUTE migrate_stmt;
DEALLOCATE PREPARE migrate_stmt;

SET @update_height_adjustable_sql = CONCAT('
    UPDATE
        ', @destination_db, '.furniture
    SET
        height_adjustable = REPLACE(height_adjustable, ";", ",")
    WHERE
        height_adjustable LIKE "%;%";
');

SET @update_item_id_sql = CONCAT('
    UPDATE
        ', @destination_db, '.catalog_items
    SET
        item_id = SUBSTRING_INDEX(item_id, ";", 1)
    WHERE
        item_id LIKE "%;%";
');

PREPARE update_item_id_stmt FROM @update_item_id_sql;
EXECUTE update_item_id_stmt;
DEALLOCATE PREPARE update_item_id_stmt;


PREPARE update_height_adjustable_stmt FROM @update_height_adjustable_sql;
EXECUTE update_height_adjustable_stmt;
DEALLOCATE PREPARE update_height_adjustable_stmt;

SET @update_height_adjustable_sql = CONCAT('
    UPDATE
        ', @destination_db, '.furniture
    SET
        height_adjustable = REPLACE(height_adjustable, " ", "")
    WHERE
        height_adjustable LIKE "% %";
');

PREPARE update_height_adjustable_stmt FROM @update_height_adjustable_sql;
EXECUTE update_height_adjustable_stmt;
DEALLOCATE PREPARE update_height_adjustable_stmt;

SET @update_item_id_sql = CONCAT('
    UPDATE
        ', @destination_db, '.catalog_items
    SET
        item_id = SUBSTRING_INDEX(item_id, ";", 1)
    WHERE
        item_id LIKE "%;%";
');

SET @update_item_id_sql = CONCAT('
    UPDATE
        ', @destination_db, '.catalog_items
    SET
        item_id = SUBSTRING_INDEX(item_id, ":", 1)
    WHERE
        item_id LIKE "%:%";
');

PREPARE update_item_id_stmt FROM @update_item_id_sql;
EXECUTE update_item_id_stmt;
DEALLOCATE PREPARE update_item_id_stmt;

PREPARE update_item_id_stmt FROM @update_item_id_sql;
EXECUTE update_item_id_stmt;
DEALLOCATE PREPARE update_item_id_stmt;

SET @delete_no_match_sql = CONCAT('
    DELETE FROM
        ', @destination_db, '.catalog_items
    WHERE
        item_id NOT IN (SELECT id FROM ', @destination_db, '.furniture);
');

PREPARE delete_no_match_stmt FROM @delete_no_match_sql;
EXECUTE delete_no_match_stmt;
DEALLOCATE PREPARE delete_no_match_stmt;
