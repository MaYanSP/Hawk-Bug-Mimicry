# Hawk Bug Mimicry Model

To setup, simply download the NetLogo file and run it on your system. Keep the "results" folder in the same folder as mimicry.nlogo if you wish to record your results in a csv file using the "record-results" toggle switch.
An R file is included for graph visualisations.

## Model Basics

In the model there are 3 types of prey and 1 type of predator. These are toxic bugs, mimic bugs, harmless bugs, and hawks, respectively. Any given prey has 2 important traits (outide of energy and speed) - toxic and pattern. Toxic bugs have a toxic value between 0.1 - 1, and an equal pattern value (e.g. toxic = 0.25, pattern = 0.25). Mimics have a toxic value of 0 and some pattern value between 0.1 - 1. (e.g. toxic = 0, pattern = 0.7). Harmless bugs have toxic = 0 and pattern = 0.

Bugs look for food that spawns constantly to gain energy which is lost when moving and reproducing. Hawks hunt bugs for energy.

Hawks are capable of 'learning' and avoiding bugs that advertise themselves as toxic using their LearnedAvoidance trait. When eating a toxic bug, hawks will gain less energy (or even lose energy if the bug is toxic enough) and then tweak their LearnedAvoidance value (from 0 - 1). Hawks exclude all bugs with pattern > 1 - LearnedAvoidance from their potential prey and will not hunt them (e.g. if LearnedAvoidance is 0.3, they will only hunt bugs with 0 < pattern < 0.7, but won't hunt bugs with pattern = 0.75). Similarly, if they predate on a "toxic" bug and it turns out to be a mimic, they will reduce their LearnedAvoidance value. This is superseded by the food-desparation-threshold, which lets hawks eat ANY prey once their energy drops below the threshold level (e.g. they will eat even an extremely toxic bug if threshold = 15 and their energy = 10).

If you wish to turn off the natural selection aspect of the model, simply turn mutation-chance down to 0%. Otherwise, bugs can mutate upon reproduction, creating toxic/mimic/harmless bugs, or just tweaking their values slightly in the next generation, and hawks can mutate to increase or decrease their learning sensitivity (how strongly they learn/associate toxicity with pattern).
