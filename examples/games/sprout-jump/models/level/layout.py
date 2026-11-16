# Sprout Jump: the level, as data. The single source for the level's geometry (make_level.py writes
# the hedra command files from it) and for the collision map in scene/game.as (make_level.py --as
# prints the AssemblyScript tables pasted between "// LEVEL BEGIN" and "// LEVEL END").
# Metres, Y up; the hero runs along X at z 0. A good player clears it in about a minute.
WATER_Y = -0.9          # the brook and the pond (the camera-carried water band)
WATER_END = 104.0        # past this the oak's crown: a fall is off the bottom of the screen

# solid blocks: kind, x0, x1, top (they reach down into the water, or to the ground)
SOLIDS = [
    ('bed', -6.0, 8.0, 0.0),
    ('pot', 4.6, 5.6, 0.8),
    ('bed', 10.0, 19.0, 0.0),
    ('pot', 16.4, 17.6, 1.3),
    ('bed', 21.4, 28.0, 0.6),
    ('step', 28.0, 29.6, 1.5),
    ('step', 29.6, 31.2, 2.4),
    ('wall', 35.6, 43.0, 2.6),
    ('bed', 50.0, 58.5, 1.2),
    ('bed', 66.5, 72.0, 1.0),
    ('crate', 72.0, 75.0, 2.2),
    ('pot', 77.4, 78.6, 2.0),
    ('pot', 80.2, 81.4, 2.8),
    ('step', 86.4, 90.0, 2.6),
    ('bed', 92.2, 97.0, 1.6),
    ('crate', 97.0, 100.0, 2.2),
    ('crate', 100.0, 103.0, 3.2),
]

# one-way platforms (land from above, jump up through): kind, x0, x1, top
ONEWAY = [
    ('flower', 59.6, 60.9, 2.6),
    ('flower', 62.0, 63.3, 3.6),
    ('flower', 64.5, 65.8, 2.8),
    ('branch', 103.8, 107.2, 6.4),
    ('branch', 108.8, 112.0, 7.2),
    ('branch', 115.8, 119.6, 8.8),
    ('branch', 121.0, 123.2, 8.2),
    ('branch', 125.8, 130.5, 8.6),
    ('branch', 135.6, 139.4, 9.4),
    ('branch', 140.6, 144.4, 12.4),
    ('leaf', 146.0, 147.4, 11.8),
    ('leaf', 149.6, 151.0, 12.6),
    ('branch', 154.8, 158.4, 13.8),
    ('branch', 164.0, 167.0, 14.8),
    ('leaf', 168.6, 170.0, 15.6),
    ('crown', 171.6, 180.0, 16.2),
]

# moving leaf platforms (one-way, 1.6 m wide): centre x, centre top y, axis ("h" or "v"), amplitude, period s
MOVERS = [
    (33.4, 2.4, 'h', 1.0, 4.0),
    (83.8, 2.8, 'h', 1.1, 3.8),
    (113.9, 7.6, 'v', 1.1, 3.6),
    (133.0, 9.0, 'h', 1.2, 4.4),
    (152.9, 13.2, 'v', 0.9, 3.2),
    (161.2, 14.2, 'h', 1.2, 4.0),
]
MOVER_W = 1.6

# the crumbling bridge: first plank's left x, planks, plank width, top
BRIDGE = (43.0, 7, 1.0, 2.5)

# springy bell-blooms: x, the top of what they stand on
SPRINGS = [(25.0, 0.6), (102.0, 3.2), (138.8, 9.4)]

# shellbugs walk a platform top between x0 and x1; moths hover: x, y, axis, amplitude, period
BUGS = [(11.4, 15.2, 0.0), (38.4, 42.4, 2.6), (52.0, 56.4, 1.2), (87.9, 89.8, 2.6), (109.2, 111.6, 7.2), (135.9, 138.0, 9.4), (164.3, 166.7, 14.8)]
MOTHS = [(124.5, 9.3, 'v', 0.9, 2.6), (148.3, 12.9, 'h', 0.7, 3.0)]

# checkpoints: x and the top they stand on (the run starts at the first)
CHECKPOINTS = [(0.5, 0.0), (36.6, 2.6), (67.6, 1.0), (86.8, 2.6), (127.0, 8.6)]
FLAG = (177.5, 16.2)

SEEDS = [
    (2.4, 0.45),
    (3.2, 0.45),
    (5.1, 1.55),
    (8.7, 1.4),
    (9.4, 1.4),
    (12.6, 1.5),
    (13.4, 1.8),
    (14.2, 1.5),
    (17.0, 2.15),
    (20.2, 1.8),
    (25.0, 2.6),
    (25.0, 3.5),
    (25.0, 4.4),
    (29.6, 3.1),
    (33.4, 3.2),
    (39.4, 3.3),
    (40.4, 3.7),
    (41.4, 3.3),
    (44.5, 3.3),
    (46.5, 3.3),
    (48.5, 3.3),
    (53.4, 2.6),
    (55.0, 2.6),
    (60.25, 3.3),
    (62.65, 4.3),
    (65.15, 3.5),
    (69.0, 1.7),
    (73.5, 2.9),
    (76.2, 2.9),
    (78.0, 2.7),
    (79.4, 3.6),
    (80.8, 3.5),
    (83.8, 3.5),
    (88.2, 3.9),
    (91.1, 3.0),
    (94.0, 2.3),
    (95.0, 2.3),
    (98.5, 2.9),
    (102.0, 5.0),
    (103.2, 7.0),
    (105.5, 7.1),
    (110.4, 8.6),
    (113.9, 9.8),
    (116.6, 9.5),
    (117.7, 9.5),
    (118.8, 9.5),
    (124.5, 10.9),
    (128.4, 9.3),
    (133.0, 10.0),
    (138.8, 11.6),
    (138.8, 12.6),
    (142.5, 13.1),
    (148.3, 14.2),
    (152.9, 15.0),
    (156.6, 14.5),
    (161.2, 15.0),
    (165.5, 16.3),
    (169.3, 16.4),
    (174.0, 16.9),
    (175.2, 16.9),
]
