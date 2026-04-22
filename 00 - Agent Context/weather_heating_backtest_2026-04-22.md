# Weather-Aware Heating — Backtest Report
# 2026-04-22 | Zurich region, Switzerland

## 1. Data Sourcing Methodology

**Source:** Open-Meteo ERA5 reanalysis archive (`archive-api.open-meteo.com`), queried 2026-04-22.
- Parameters: `temperature_2m_max`, `temperature_2m_min`, daily, Europe/Zurich timezone.
- Location: Zurich region, Switzerland (nearest ERA5 grid point at elevation 742 m).
- Coverage retrieved: 2026-03-19 through 2026-04-21 (34 days, to provide pre-period seeding data).
- **Data substitution noted:** The automation uses met.no *forecast* values (forecast[0]/[1]) at 22:00. This backtest substitutes ERA5 *reanalysis actuals* for the same dates. Reanalysis values are more accurate than the forecast would have been at 22:00, so the backtest represents a best-case (oracle) scenario — real performance may diverge slightly on days with forecast errors, typically ±1–2 °C on daily means.
- **April 22 (today):** ERA5 archive does not yet have actuals for today (typical ~5-day processing lag). The April 21 run's "tomorrow_mean" (Apr 22) is marked as pending.
- **No gaps in coverage** for the primary window (Mar 23–Apr 21).
- **Cold-start seeding:** System helpers initialized at 12.0 °C per the YAML spec. Pre-period actuals (Mar 19–22) are available but not used in the simulation — the cold-start begins with all three slots at 12.0 before the first run on Mar 23 at 22:00.

---

## 2. Daily Table — 30 Days (2026-03-23 to 2026-04-21)

**Reading the table:** Each row is one 22:00 automation run. "Trailing avg" is the 3-day average computed in that run (today_mean + day1 + day2). "Tomorrow mean" is the day D+1 actual mean (substituted for forecast). "Resulting setpoints" take effect from 22:00 that day until the next 22:00 run.

| Run date | High °C | Low °C | Today mean | Trail avg | Tmrw mean | Delta | Offset | Kitchen | LR | Office |
|------------|---------|--------|------------|-----------|-----------|-------|--------|---------|------|--------|
| 2026-03-23 | 9.8 | -0.6 | 4.6 | 9.5 * | 4.7 | -4.8 | +0.5 | 20.5 | 21.5 | 19.5 |
| 2026-03-24 | 11.3 | -1.9 | 4.7 | 7.1 * | 5.7 | -1.4 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-03-25 | 11.3 | 0.1 | 5.7 | 5.0 | 0.6 | -4.4 | +0.5 | 20.5 | 21.5 | 19.5 |
| 2026-03-26 | 3.5 | -2.3 | 0.6 | 3.7 | -0.3 | -4.0 | +0.5 | 20.5 | 21.5 | 19.5 |
| 2026-03-27 | 2.7 | -3.3 | -0.3 | 2.0 | 0.5 | -1.5 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-03-28 | 5.3 | -4.3 | 0.5 | 0.3 | 1.6 | +1.3 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-03-29 | 4.4 | -1.2 | 1.6 | 0.6 | 2.3 | +1.7 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-03-30 | 6.0 | -1.5 | 2.3 | 1.5 | 1.3 | -0.2 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-03-31 | 4.4 | -1.9 | 1.3 | 1.7 | 2.0 | +0.3 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-01 | 5.9 | -1.9 | 2.0 | 1.9 | 3.0 | +1.1 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-02 | 8.7 | -2.7 | 3.0 | 2.1 | 5.6 | +3.5 | -0.5 | 19.5 | 20.5 | 18.5 |
| 2026-04-03 | 10.9 | 0.2 | 5.6 | 3.5 | 8.9 | +5.4 | -1.5 | 18.5 | 19.5 | 17.5 |
| 2026-04-04 | 14.2 | 3.5 | 8.9 | 5.8 | 10.6 | +4.8 | -0.5 | 19.5 | 20.5 | 18.5 |
| 2026-04-05 | 19.3 | 1.9 | 10.6 | 8.4 | 11.5 | +3.1 | -0.5 | 19.5 | 20.5 | 18.5 |
| 2026-04-06 | 16.3 | 6.6 | 11.5 | 10.3 | 11.5 | +1.2 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-07 | 18.6 | 4.4 | 11.5 | 11.2 | 11.7 | +0.5 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-08 | 18.4 | 5.0 | 11.7 | 11.6 | 11.5 | -0.1 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-09 | 18.7 | 4.2 | 11.5 | 11.6 | 9.3 | -2.3 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-10 | 13.5 | 5.0 | 9.3 | 10.8 | 12.4 | +1.6 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-11 | 19.3 | 5.5 | 12.4 | 11.1 | 8.3 | -2.8 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-12 | 10.4 | 6.2 | 8.3 | 10.0 | 6.9 | -3.1 | +0.5 | 20.5 | 21.5 | 19.5 |
| 2026-04-13 | 8.8 | 5.0 | 6.9 | 9.2 | 6.5 | -2.7 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-14 | 8.6 | 4.4 | 6.5 | 7.2 | 7.1 | -0.1 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-15 | 11.4 | 2.7 | 7.1 | 6.8 | 9.3 | +2.5 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-16 | 16.3 | 2.3 | 9.3 | 7.6 | 10.3 | +2.7 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-17 | 17.5 | 3.1 | 10.3 | 8.9 | 11.1 | +2.2 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-18 | 18.9 | 3.2 | 11.1 | 10.2 | 11.1 | +0.9 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-19 | 15.5 | 6.7 | 11.1 | 10.8 | 8.9 | -1.9 | 0 | 20.0 | 21.0 | 19.0 |
| 2026-04-20 | 13.9 | 3.8 | 8.9 | 10.4 | 7.3 | -3.1 | +0.5 | 20.5 | 21.5 | 19.5 |
| 2026-04-21 | 12.0 | 2.5 | 7.3 | 9.1 | — † | — | — | — | — | — |

\* Trailing avg inflated by cold-start seeds (12.0 °C). See Section 6.
† Apr 22 actual not yet available in ERA5 archive (processed with ~5-day lag). The trailing avg of 9.1 °C has been computed; tomorrow_mean pending.

---

## 3. Summary Statistics

| Metric | Value |
|--------|-------|
| Days with offset = 0 | 21 of 29 complete runs (72%) |
| Days with offset +0.5 | 5 (Mar 23, Mar 25, Mar 26, Apr 12, Apr 20) |
| Days with offset -0.5 | 3 (Apr 02, Apr 04, Apr 05) |
| Days with offset +1.5 | 0 |
| Days with offset -1.5 | 1 (Apr 03) |
| Max absolute offset | 1.5 °C on 2026-04-03 |
| Sign flips (+ to - or - to +, ignoring zero) | 2 (late-March + cluster → April warming cluster; April warming → April 12 boost) |
| Longest run of identical offset | 7 consecutive zeros (Apr 13–19) |
| Mean absolute offset (29 complete runs) | 0.19 °C |
| Median absolute offset | 0 °C |
| Non-zero offset runs | 9 of 29 (31%) |

---

## 4. Qualitative Analysis

**Frequency — not too timid, not too volatile.** 9 non-zero triggers in 30 days (~31%) falls between the "< 2 times → timid" and "> 15 times → volatile" thresholds stated in the request. The distribution is coherent: the late-March cold snap produced three consecutive boosts, the early-April spring surge produced a four-run setback cluster, then mostly silence as temperatures stabilized.

**Late-March cold snap (Mar 25–26):** The system correctly fired +0.5 boosts on both days. Mar 25 saw a drop from 5.7 °C mean to 0.6 °C (delta = -4.4 vs trailing avg 5.0), and Mar 26 saw mean of -0.3 against a trailing avg of 3.7 (delta = -4.0). Both correctly landed in the ±0.5 tier. The system was slower to react on Mar 27 (coldest day, -0.3 mean) because at 22:00 it looked at Mar 28 (0.5 mean) — barely warmer than the trailing avg of 2.0, delta = -1.5, correctly no trigger. This is not a miss: the worst cold was behind the forecast by that point.

**Early-April spring warming:** Apr 02 fired -0.5, Apr 03 fired -1.5 (the only max-tier event), Apr 04 and Apr 05 fired -0.5. This is correct behavior — the trailing avg was lagging behind a rapid +6 °C week-over-week rise. The lag is by design (thermal mass rationale in the package header).

**Apr 09 near-miss (Apr 10 drop):** On Apr 09 at 22:00, the system looked at Apr 10's forecast (9.3 °C mean). The trailing avg was 11.6. Delta = -2.3 — just under the 3 °C noise floor. Apr 10 was indeed a cooler day (high only 13.5 °C) in an otherwise warm spell. The non-trigger is defensible: a 2.3 °C delta in a thermal-mass building doesn't warrant action. The rooms were already at base setpoints; no harm done.

**Apr 11 anomaly:** Apr 11 had a high of 19.3 °C (warmest day in the window) but the trailing avg was 11.1 °C on the run from Apr 10. Delta = +1.6 → no trigger. Correct. The system had already set back on Apr 04–05; by Apr 10 the trailing avg had risen enough that the day's actual warmth was no longer an outlier against it.

**Apr 12 and Apr 20 +0.5 boosts:** Both are at the edge of the 3 °C threshold (deltas of -3.1 each). Both represent genuine cooling relative to the trailing window — Apr 12 after the warm spell ending, Apr 20 as early signs of a late-April cool-down. Legitimate triggers.

**Overnight cold snaps:** Late March had several nights below -3 °C. The daily means were low (e.g., -0.3 on Mar 27) but the automation looks at full-day means, not overnight minimums. The system correctly caught the multi-day cold pattern through the trailing average. No blind spots apparent here.

**Weekend-weather patterns:** No structural issue — the automation is time-based (22:00 daily), not aware of weekday/weekend. Temperature patterns don't correlate with day-of-week in this dataset.

---

## 5. Recommended Tweaks

**None warranted.** The 9/29 trigger rate is reasonable for a transitional spring month. The logic fired on every genuine weather event in this window: the March cold snap, the early-April spring surge, and two marginal cool-down events in mid-to-late April. It did not false-fire during the stable warm spell (Apr 06–19), where daily deltas stayed comfortably below 3 °C despite day-to-day variation.

One observation worth monitoring but not acted on yet: The 3 °C noise floor let through the Apr 09 drop (delta = -2.3) and the Apr 11 warm spike (delta = +1.6) without action, which is correct for single-day noise. However, during mid-April the temperature was rising steadily (+2–3 °C/day) across Apr 15–18, and each day individually sat just under the 3 °C threshold (deltas of +2.5, +2.7, +2.2, +0.9). The trailing average tracked the rise well enough that the system naturally held off — the rising trailing avg kept pace with rising actuals. This is correct behavior, not a gap. If this setup were applied to a shoulder-season with faster swings, the 3 °C floor might benefit from review, but within this 30-day window it performs as designed.

---

## 6. Cold-Start Behavior

**Initial state:** day1 = day2 = 12.0 °C (seeded per YAML spec). This represents an "average April Zurich" guess. Actual late-March means in this window were 4.6–5.7 °C — significantly colder than the seed.

**Convergence trace:**

| After run on | day1 | day2 | Trailing avg | Seed influence |
|--------------|------|------|--------------|----------------|
| Mar 23 | 4.6 | 12.0 | 9.5 | Both slots contain at least one real value; one slot still 12.0 |
| Mar 24 | 4.7 | 4.6 | 7.1 | One slot still contains 12.0 (via day2) |
| Mar 25 | 5.7 | 4.7 | 5.0 | Both slots real — **fully converged** |
| Mar 26 | 0.6 | 5.7 | 3.7 | Fully real |

**Convergence: 3 runs (3 calendar days).**

**Impact of cold-start on decisions:** The inflated trailing avg on runs 1–2 caused the delta to appear larger than it truly was. On run 1 (Mar 23), the real 3-day avg would have been approximately 5.0 °C (using Mar 21–23 actuals: 4.4 + 4.6 + 5.7 = 14.7/3 ≈ 4.9), not the computed 9.5 °C. With delta = 4.7 - 4.9 = -0.2, the real answer would have been offset = 0. The cold-start instead produced +0.5.

**The cold-start produced one incorrect trigger** (Mar 23 run → +0.5 boost for Mar 24). Mar 24 was actually 4.7 °C mean — similar to prior days — and didn't need a boost. The +0.5 offset on Mar 24 was a false positive, harmless in practice but worth noting. By run 3 (Mar 25), the cold-start influence was gone.

**Recommendation on seed value:** 12.0 °C is reasonable for mid-April deployment but warm for late-March. Since this system will be deployed in April 2026 when actual outdoor means are 7–11 °C, seeding at 12.0 is close enough. The 3-day convergence window is short. No change needed.

---

*Data source: Open-Meteo ERA5 archive, queried 2026-04-22. ERA5 reanalysis actuals substituted for met.no forecast values — see Section 1.*
*Automation spec: `config/packages/weather_aware_heating.yaml` (Gate 2 reviewed 2026-04-22).*
