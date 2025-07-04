extensions [csv]

globals [
  output-file
]

breed [bugs bug]
breed [hawks hawk]
breed [foods food]
bugs-own [
  pattern
  toxic
  speed
  energy
]
hawks-own [
  speed
  energy
  learned-avoidance
  avoidance-threshold
  learning-sens
]


to setup
  resize-world (world-size * -1) (world-size) (world-size * -1) (world-size)
  set-patch-size 350 / world-size
  set-default-shape bugs "bug"
  set-default-shape hawks "hawk"
  ca
  summon-bugs bug-population
  summon-hawks hawk-population
  reset-ticks
  start-recording-results
end

to go
  record-the-results
  if count bugs = 0 and count hawks = 0  or ticks >= tick-cap [
    stop
  ]
  tick
  if ticks mod ticks-per-food = 0 [
    summon-food food-amount
  ]
  if count bugs < bug-population and constant-populations [
    summon-bugs 1
  ]
  ask bugs [
    natural-selection-give-birth
    find-food
    lose-energy
  ]
  ask hawks [
    hawk-natural-selection-birth
    set-color
    decay-memory
    hunt
    lose-energy
  ]
end

to summon-bugs [x]
  create-bugs x [
    setxy random-xcor random-ycor
    set energy starting-energy
    set speed 0.5
    ifelse random-float 1 < toxic-proportion [
      set toxic 0.1 + random-float 0.9
    ] [
      set toxic 0
    ]
    ifelse toxic >= 0.1 [
      set pattern toxic
    ] [
      ifelse random-float 1 < mimic-proportion [
        set pattern 0.1 + random-float 0.9
      ] [
        set pattern 0
      ]
    ]
    ifelse pattern = 0 [
      set color green
    ] [
      set color scale-color violet pattern 1.5 0
    ]
  ]
end

to summon-hawks [x]
  create-hawks x [
    setxy random-xcor random-ycor
    set learned-avoidance 0 ; avoidance applies to purple only
    set learning-sens random-float 1
    set-color
    set speed 0.6
    set size 2
    set energy starting-energy
  ]
end

to move-forward
  rt random-float max-turn * 2 - max-turn
  fd speed
end

to hunt-testing ; currently not in use due to overcomplicating the model unneccesarliy
  let nearby-bugs bugs in-radius 5 with [pattern <= 1 - learned-avoidance]
  ifelse any? nearby-bugs [
    let closest-bug min-one-of nearby-bugs [distance myself]
    let turn towardsxy [xcor] of closest-bug [ycor] of closest-bug ; checks the rt necessary to face bug
    ifelse turn > 360 - max-turn or turn < max-turn [ ; checks if the turn is smaller than the max-turn (or larger than 360 - max-turn)
      face closest-bug ; if turn is smaller, just make the turn
    ] [
      ifelse turn > 180 [ ; if turn is not smaller
        rt max-turn ; if the turn is to the right, turn max-turn to the right
      ] [
        lt max-turn ; if it's to the left, do the same but left
      ]
    ]
    fd speed
    kill-bug
  ] [
    move-forward
  ]
end

to hunt
  let nearby-bugs bugs in-radius 5 with [pattern <= 1 - [learned-avoidance] of myself]
  if energy < food-desparation-threshold [
    set nearby-bugs bugs in-radius 5
  ]
  ifelse any? nearby-bugs [
    let closest-bug min-one-of nearby-bugs [distance myself]
    face closest-bug
    fd speed
    kill-bug
  ] [
    move-forward
  ]
end

to kill-bug
  let target one-of bugs in-radius 1
  if target != nobody [
    let gained-energy energy-from-bug
    if [pattern] of target > 0 [
      ifelse [toxic] of target > 0 [ ; Random Chance for toxic bug to HARM the hawk by reducing energy rather than gaining it - more toxic bugs more likely to cause energy loss
        set gained-energy gained-energy - ([toxic] of target * 1.5 * gained-energy) ; simpler function than the previous,
        set learned-avoidance min list 1 (learned-avoidance + learning-sens / 2 * [toxic] of target) ; if the hawk was harmed by the toxic bug, increase learned-avoidance (but no more than 1)
      ] [
        set learned-avoidance min list 1 (learned-avoidance * (1 - learning-sens / 10)) ; if the bug was advertising itself as toxic but nothing happened, become less cautious/avoidant - the higher the learning sensitivity, the greater the effect
      ]
    ]
    ask target [
      die
    ]
    set energy energy + gained-energy
  ]
end

to set-threshold ; redundant code
  if ticks mod 100 = 0 [
    set avoidance-threshold random-float 1
  ]
end

to decay-memory
  set learned-avoidance learned-avoidance * 0.999
end

to set-color
  if breed = hawks [
    set color scale-color red (learned-avoidance + 0.25) 1.5 0
  ]
end

to find-food
  let nearby-foods foods in-radius 5
  ifelse any? nearby-foods [
    let closest-food min-one-of nearby-foods [distance myself]
    face closest-food
    fd speed
    eat-food
  ] [
    move-forward
  ]
end

to eat-food
  let target one-of foods in-radius 1
  if target != nobody [
    set energy energy + energy-from-food
    ask target [
      die
    ]
  ]
end

to summon-food [x]
  create-foods x [
    setxy random-xcor random-ycor
    set shape "circle"
    set color yellow
    set size 0.5
  ]
end

to lose-energy
  let energy-lost 0.1
  if breed = bugs [
    if toxic > 0 [
      set energy-lost energy-lost + abs (toxicity-cost / 5 * 100 * toxic / (100 * toxic - 101)) ; exponential cost of toxicity to prevent extremely high toxicity at a low cost
    ]
    if is-mimic [
      set energy-lost energy-lost + abs (mimicry-cost / 5 * 100 * pattern / (100 * pattern - 101)) ; exponential cost of mimicry to prevent extremely high mimicry at a an even lower cost
    ]
  ]

  set energy energy - energy-lost
  if energy <= 0 [
    die
  ]
end

to debug-energy [x]
  print "old"
  print 0.1 + 0.1 * x * toxicity-cost
  print 0.1 + 0.1 * x * mimicry-cost
  print "new"
  print 0.1 + abs (toxicity-cost * 100 * x / (100 * x - 100))
  print 0.1 + abs (mimicry-cost * 100 * x / (100 * x - 100))
end

to give-birth
  if energy > 100 [
    hatch 1 [
      set energy starting-energy
      setxy [xcor] of myself + random-float 4 - 2 [ycor] of myself + random-float 4 - 2
    ]
    set energy energy - 25
  ]
end

to natural-selection-give-birth
  if energy > 100 [
    hatch 1 [
      set energy starting-energy
      if random-float 100 < mutation-chance [ ; if mutation occuring
        ifelse toxic = 0 [
          set toxic 0.1 + random-float 0.1 ; if NOT toxic, set toxicity to random value between 0.1 - 0.2
        ] [
          set toxic toxic + random-float 0.2 - 0.1 ; if already toxic, +- a value from 0 - 0.1 to toxicity
          if toxic < 0.1 [
            set toxic 0 ; if the toxicity is now lower than 0.1, become NON toxic (toxicity = 0)
          ]
          if toxic > 1 [
            set toxic 1 ; cap at 1
          ]
        ]
      ]
      if random-float 100 < mutation-chance and toxic = 0 [ ; if mutation occurs and you are NOT toxic (toxicity = 0)
        ifelse pattern = 0 [ ; if you're harmless,
          set pattern 0.1 + random-float 0.1 ; become a mimic with a pattern between 0.1 - 0.2
        ] [
          set pattern pattern + random-float 0.2 - 0.1 ; if you are already a mimic, change pattern +- a value from 0 - 0.1
          if pattern < 0.1 [ ; if pattern goes below 0.1
            set pattern 0 ; become a harmless bug
          ]
          if pattern > 1 [
            set pattern 1 ; cap at 1
          ]
        ]
      ]
      if random-float 100 < mutation-chance [ ; if mutation occurs - just become harmless. workaround to buggy natural selection (?) causing no harmless bugs even when its most efficient
        set toxic 0
        set pattern 0
      ]
      if toxic > 0 [
        set pattern toxic
      ]
      set color scale-color violet pattern 1.5 0 ; give appropriate color
      if pattern = 0 [
        set color green
      ]
      setxy [xcor] of myself + random-float 4 - 2 [ycor] of myself + random-float 4 - 2 ; spawn baby in slightly diff coords
    ]
    set energy energy - 25 ; lose energy for birth
  ]
end

to hawk-natural-selection-birth
  if energy > 100 [
    hatch 1 [
      set energy starting-energy
      if random-float 100 < mutation-chance [
        set learning-sens learning-sens + random-float 0.2 - 0.1
        if learning-sens > 2 [
          set learning-sens 2
        ]
        if learning-sens < 0 [
          set learning-sens 0
        ]
      ]
      setxy [xcor] of myself + random-float 4 - 2 [ycor] of myself + random-float 4 - 2 ; spawn baby in slightly diff coords
    ]
    set energy energy - 25
  ]
end

to-report is-mimic
  ifelse toxic = 0 and pattern > 0 and pattern < 55[
    report True
  ] [
    report False
  ]
end

to start-recording-results
  if record-results [
    let date (substring date-and-time 16 27)
    let raw-time (substring date-and-time 0 15)
    let time1 (replace-item (position ":" raw-time) raw-time "-")
    let time2 (replace-item (position ":" time1) time1 "-")
    let time3 (replace-item (position "." time2) time2 "-")
    let time time3
    let extension (word date "-" time ".csv")
    set output-file (word "results/" extension)
    print output-file
    file-close-all
    file-open output-file
    file-print csv:to-row ["Ticks" "Toxic" "Mimics" "Harmless" "Hawks" "RelativeToxic" "RelativeMimics" "RelativeHarmless" "LearnedAvoidance" "LearningSens" "AvgToxicity" "AvgMimicry"] ; header
  ]
end

to record-the-results
  if record-results [
    file-open output-file
    let total count bugs
    file-print csv:to-row (list
      ticks
      (count bugs with [toxic > 0])
      (count bugs with [is-mimic])
      (count bugs with [pattern = 0])
      (count hawks)
      (ifelse-value (total > 0) [(count bugs with [toxic > 0]) / total * 100] [0])
      (ifelse-value (total > 0) [(count bugs with [is-mimic]) / total * 100] [0])
      (ifelse-value (total > 0) [(count bugs with [pattern = 0]) / total * 100] [0])
      (ifelse-value (count hawks > 0) [mean [learned-avoidance] of hawks] [0])
      (ifelse-value (count hawks > 0) [mean [learning-sens] of hawks] [0])
      (ifelse-value (count bugs with [toxic > 0] > 0) [mean [toxic] of bugs with [toxic > 0]] [0])
      (ifelse-value (count bugs with [is-mimic] > 0) [mean [pattern] of bugs with [is-mimic]] [0]))
    file-close
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
922
723
-1
-1
4.666666666666667
1
10
1
1
1
0
1
1
1
-75
75
-75
75
0
0
1
ticks
30.0

INPUTBOX
5
45
160
105
world-size
75.0
1
0
Number

BUTTON
5
10
68
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
70
10
133
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
110
177
143
max-turn
max-turn
1
45
10.0
1
1
NIL
HORIZONTAL

SLIDER
5
245
177
278
mimic-proportion
mimic-proportion
0
1
0.25
0.01
1
NIL
HORIZONTAL

PLOT
925
10
1475
415
Average Avoidance of Hawks
Ticks
Mean Learned Avoidance
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Avoidance" 1.0 0 -16777216 true "" "if count hawks > 0 [plot mean [learned-avoidance] of hawks]"
"Learning Sensitivity" 1.0 0 -2064490 true "" "if count hawks > 0 [plot mean [learning-sens] of hawks]"

SLIDER
5
280
177
313
toxic-proportion
toxic-proportion
0
1
0.25
0.01
1
NIL
HORIZONTAL

PLOT
925
420
1475
730
All Populations
Ticks
Count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Toxic" 1.0 0 -8630108 true "" "plot count bugs with [toxic > 0]"
"Mimics" 1.0 0 -11221820 true "" "plot count bugs with [toxic = 0 and pattern > 0] "
"Harmless" 1.0 0 -10899396 true "" "plot count bugs with [toxic = 0 and pattern = 0]"
"Hawks" 1.0 0 -2674135 true "" "plot count hawks"

SLIDER
5
175
177
208
bug-population
bug-population
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
5
210
177
243
hawk-population
hawk-population
0
25
10.0
1
1
NIL
HORIZONTAL

SLIDER
5
375
177
408
bug-speed
bug-speed
0.5
1.5
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
5
410
177
443
hawk-speed
hawk-speed
0.5
1.5
0.6
0.1
1
NIL
HORIZONTAL

SWITCH
5
315
177
348
constant-populations
constant-populations
1
1
-1000

SLIDER
5
630
177
663
food-amount
food-amount
1
15
15.0
1
1
NIL
HORIZONTAL

SLIDER
5
665
177
698
ticks-per-food
ticks-per-food
5
50
5.0
5
1
NIL
HORIZONTAL

SLIDER
5
700
177
733
starting-energy
starting-energy
1
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
5
735
177
768
energy-from-food
energy-from-food
1
25
6.0
1
1
NIL
HORIZONTAL

PLOT
1480
420
1885
730
Relative Bug Population
Ticks
%
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Toxic" 1.0 0 -8630108 true "" "plot (count bugs with [toxic >= 0.1] / count bugs * 100)"
"Mimic" 1.0 0 -11221820 true "" "plot (count bugs with [toxic = 0 and pattern > 0] / count bugs * 100)"
"Harmless" 1.0 0 -10899396 true "" "plot (count bugs with [toxic = 0 and pattern = 0] / count bugs * 100)"

SLIDER
5
770
177
803
energy-from-bug
energy-from-bug
1
50
12.0
1
1
NIL
HORIZONTAL

SLIDER
5
515
180
548
food-desparation-threshold
food-desparation-threshold
1
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
620
765
792
798
mutation-chance
mutation-chance
0
100
10.0
0.5
1
%
HORIZONTAL

TEXTBOX
625
730
795
776
Natural Selection
20
0.0
1

TEXTBOX
10
150
160
171
Starting Populations
17
0.0
1

TEXTBOX
10
350
160
371
Agent Parameters
17
0.0
1

TEXTBOX
10
585
160
626
Environment Parameters
17
0.0
1

BUTTON
210
725
352
758
Most Avoidant Hawk
watch max-one-of hawks [learned-avoidance]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
355
725
477
758
Most Naive Hawk
watch min-one-of hawks [learned-avoidance]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
480
725
612
758
Reset Perspective
reset-perspective
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
210
760
350
805
Avoidance
[learned-avoidance] of max-one-of hawks [learned-avoidance] * 100
2
1
11

MONITOR
355
760
475
805
Avoidance
[learned-avoidance] of min-one-of hawks [learned-avoidance] * 100
3
1
11

SWITCH
925
735
1057
768
record-results
record-results
0
1
-1000

BUTTON
1060
735
1147
768
Close Files
file-close-all
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
5
445
180
478
toxicity-cost
toxicity-cost
0
0.25
0.03
0.01
1
NIL
HORIZONTAL

SLIDER
925
770
1097
803
tick-cap
tick-cap
10000
500000
500000.0
10000
1
NIL
HORIZONTAL

SLIDER
5
480
177
513
mimicry-cost
mimicry-cost
0
0.25
0.02
0.01
1
NIL
HORIZONTAL

PLOT
1480
10
1885
420
Average "Toxicity" of Toxic/Mimic Bugs
Ticks
Toxicity
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -8630108 true "" "ifelse count bugs with [toxic > 0] = 0 [\nplot 0\n] [\nplot mean [toxic] of bugs with [toxic > 0]\n]"
"pen-1" 1.0 0 -11221820 true "" "ifelse count bugs with [is-mimic] = 0 [\nplot 0\n] [\nplot mean [pattern] of bugs with [is-mimic]\n]"

@#$#@#$#@
## WHAT IS IT?

This model uses predators (hawks) capable of learning to test batesian mimicry of prey (bugs) that are either toxic or harmless and can display one of two patters - violet or green.

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

hawk
true
0
Polygon -7500403 true true 151 170 136 170 123 229 143 244 156 244 179 229 166 170
Polygon -16777216 true false 152 154 137 154 125 213 140 229 159 229 179 214 167 154
Polygon -7500403 true true 151 140 136 140 126 202 139 214 159 214 176 200 166 140
Polygon -16777216 true false 151 125 134 124 128 188 140 198 161 197 174 188 166 125
Polygon -7500403 true true 152 86 227 72 286 97 272 101 294 117 276 118 287 131 270 131 278 141 264 138 267 145 228 150 153 147
Polygon -7500403 true true 160 74 159 61 149 54 130 53 139 62 133 81 127 113 129 149 134 177 150 206 168 179 172 147 169 111
Circle -16777216 true false 144 55 7
Polygon -16777216 true false 129 53 135 58 139 54
Polygon -7500403 true true 148 86 73 72 14 97 28 101 6 117 24 118 13 131 30 131 22 141 36 138 33 145 72 150 147 147

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
