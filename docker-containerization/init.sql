-- Runs once on first MySQL init (volume empty). Proves data lives on the volume.

CREATE TABLE IF NOT EXISTS demo_notes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    body VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO demo_notes (body) VALUES
    ('Seeded from init.sql on first boot'),
    ('Data survives container recreate when volume is reused');

-- Jokes served by Flask (read with SELECT from `jokes`)
CREATE TABLE IF NOT EXISTS jokes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    body TEXT NOT NULL
);

INSERT INTO jokes (body) VALUES
    ('I''m afraid for the calendar. Its days are numbered.'),
    ('My wife said I should do lunges to stay in shape. That would be a big step forward.'),
    ('Why do Protestants always carry a map? Because they don''t want to get lost in the Reformation.'),
    ('I used to play piano by ear, but now I use my hands.'),
    ('Docker containers are like teenagers: they don''t listen, but they''re very portable.');
