/// Clamps a raw strength to the supported 1..3 range.
int normalizeStrength(int value) => value < 1 ? 1 : (value > 3 ? 3 : value);
