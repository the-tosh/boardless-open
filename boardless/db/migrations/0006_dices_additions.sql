DELETE FROM game_rules__dices;
DELETE FROM dices;

ALTER TABLE "dices" ADD COLUMN "name" TEXT NOT NULL;
ALTER TABLE "dices" ADD COLUMN "img_32" TEXT NOT NULL;

INSERT INTO "dices" (num_of_sides, start_num, step, name, img_32)
    VALUES
    (4, 1, 1, 'd4', 'img/play/d4_32x32.png'),
    (6, 1, 1, 'd6', 'img/play/d6_32x32.png'),
    (8, 1, 1, 'd8', 'img/play/d8_32x32.png'),
    (10, 1, 1, 'd10', 'img/play/d10_32x32.png'),
    (20, 1, 1, 'd20', 'img/play/d20_32x32.png'),
    (10, 0, 10, 'd100', 'img/play/d10_32x32.png');