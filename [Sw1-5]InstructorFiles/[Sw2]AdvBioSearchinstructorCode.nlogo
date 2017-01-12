 ;----------------------------------------------------------------------------------------------
 ;; INSTRUCTOR FILE
 ;----------------------------------------------------------------------------------------------

 ;; Elizabeth E. Esterly
 ;; elizabeth@cs.unm.edu
 ;; The University of New Mexico
 ;; Swarmathon 2: Advanced Bio-Inspired Search
 ;; version 1.0
 ;; Last Revision 01/05/2017

 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;    Globals and Properties    ;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;----------------------------------------------------------------------------------------------
 
 ;;The default agent in Netlogo is a turtle. We want to use robots! 
 breed [robots robot]
 
 ;;Let's load the bitmap extension to use a Mars planet background.
 extensions[ bitmap ]
 
 ;;We need to keep track of how many rocks are left to gather.
 globals [ numberOfRocks ]         
 
;;Each robot knows some information about itself:
 robots-own [
   ;;Is it in the searching? state?
   searching?     
   
   ;;Is it in the returning? state?                 
   returning?
   
   ;;1) Is it usingPheromone?
   usingPheromone?
   ]           
 
 ;;Each patch knows some information about itself:
 patches-own [
   
   ;;What color they start as.
   baseColor   
   
   ;;2) How much time they have left of pheromone before it evaporates.                    
   pheromoneCounter
   
   ]
 
  
 
 ;--------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;       setup           ;;
 ;;;;;;;;;;;;;;;;;;;;;;;;;;;
 
 to setup 
                  
   ;;Clear all the data for a fresh start
   ca
   
   ;;Import the background image of Mars
   bitmap:copy-to-pcolors bitmap:import "mars.jpg" true

   ;;Set the global numberOfRocks to 0 to start 
   set numberOfRocks 0
  
   ;; Create a number of robots based on the slider bar. 
   ;; Set their properties and robots-own variable values.
   create-robots numberOfRobots [
     set shape "robot"
     set size 8
     set searching? true
     set returning? false
     
     ;;1) Robots start off not using pheromone.
     set usingPheromone? false
   ]
   
   ;; Patches remember their starting color
   ask patches [
     set baseColor pcolor
     
     ;;2) There's no pheromone on the patches yet, so 
     ;;   set the counter to 0.
     set pheromoneCounter 0
     ]
   
   
   ;;Set some random patches to the color yellow to represent rocks. 
   let targetPatches singleRocks
     while [targetPatches > 0][
       ask one-of patches[
         if pcolor != black and pcolor != yellow[
           set pcolor yellow
           set targetPatches targetPatches - 1
         ]
       ]
     ]
     set numberOfRocks (numberOfRocks + singleRocks)


   ;; Make some clusters of 5 rocks.
   let targetClusters clusterRocks
     while [targetClusters > 0][
       ask one-of patches[
         if pcolor != black and pcolor != yellow 
            and [pcolor] of neighbors4 != black and [pcolor] of neighbors4 != yellow[
           set pcolor yellow
           ask neighbors4[ set pcolor yellow ]
           set targetClusters targetClusters - 1
         ]
       ]
     ]
     set numberOfRocks (numberOfRocks + (clusterRocks * 5))

     
   ;;3) Create some larger clusters of 29 rocks. 
   let targetLargeClusters largeClusterRocks
   while [targetLargeClusters > 0][
     ask one-of patches[
       if pcolor != black and pcolor != yellow and [pcolor] of patches in-radius 3 != black 
       and [pcolor] of patches in-radius 3 != yellow[
         set pcolor yellow
         ask patches in-radius 3 [set pcolor yellow]
         set targetLargeClusters targetLargeClusters - 1
       ]
     ]
     ]
   set numberOfRocks numberOfRocks + (largeClusterRocks * 29)
   
   ;;Make the base. 
   ask patches
   [
     if distancexy 0 0 = 0 [set pcolor green]
   ]                      
                                        
  ;;reset ticks to 0
  reset-ticks

 end
 
 ;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;;
 ;;       Go        ;;
 ;;;;;;;;;;;;;;;;;;;;;
 to go
   
   ;;run the program until all rocks are collected
   if (numberOfRocks > 0)
   [
     ask robots
     [
       ;;These statements control the main behavior of the robots.
       ;; 1) There are two cases where a robot is using pheromone:
       ;;    - It found a sufficient density of rocks and is laying a trail back to the base
       ;;      for other robots to follow.
       ;;    - It picked up a trail at the base and is currently following it.
       ;;    The first case is handled by return-to-base.
       ;;    We'll need to take care of the second here:
       ;;    If a robot is using pheromone but is not currently returning to the base, it
       ;;    must be following a trail.
       if usingPheromone? and not returning? [check-for-trails]
       if searching? [look-for-rocks]
       if returning? [return-to-base]
       
       ;;Make the robots move.
       wiggle
     ]   
     
     ;;2) Manage the pheromone on the patches.
     ask patches
     [
       ;; Handle the case where the pheromoneCounter is down to 1 separately 
       ;; so that we don't go into negatives.
       if pheromoneCounter = 1[
         set pheromoneCounter 0
         set pcolor baseColor
       ]
       ;;Colors denote trail strength.
       if pheromoneCounter > 1 and pheromoneCounter <= 50 [set pcolor cyan - 13]
       if pheromoneCounter > 50 and pheromoneCounter <= 100 [set pcolor cyan - 10]
       if pheromoneCounter > 0 [set pheromoneCounter pheromoneCounter - 1]
     ]
   ]
  
   ;;  The challenge from Swarmathon 1 to get the robots to go back to the base
   ;;  after all rocks are colllected is implemented here.  
   if not any? patches with [pcolor = yellow][
     set numberOfRocks 0
     ask robots[
       set searching? false
       set returning? true
       while [pcolor != green][
         return-to-base
         fd 1
       ]
     ]
     stop
   ]
   ;;advance the clock
   tick
   
 end
 
 
 
 ;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;
 ;;    wiggle      ;;
 ;;;;;;;;;;;;;;;;;;;;
    
 to wiggle
   
   ;; Turn right 0 - maxAngle degrees.    
   right random maxAngle
          
   ;; Turn left 0 - maxAngle degrees.
   left random maxAngle
   
   ;; Turn around and face the origin if we hit the edge of the planet 
   ;; (the patch color is black at the edge of the planet).
   if pcolor = black [ facexy 0 0 ]

   ;; Go forward one patch.
   forward 1
  
 end
 
 
 ;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;
 ;; look-for-rocks ;;
 ;;;;;;;;;;;;;;;;;;;;
 
 to look-for-rocks
   ;;Ask the 8 patches around the robot if the patch color is yellow
   ask neighbors[
     if pcolor = yellow[
     ;;   If it is, take one rock away,
     ;;   and change the patch color back to its original color.
       set numberOfRocks (numberOfRocks - 1)  
       set pcolor baseColor
       
       ;; The robot asks itself to:
       ;; Turn off searching? 
       ;; Turn on returning?
       ;; Set its shape to the one holding the rock.
       ask myself [ 
         set searching? false
         set returning? true
         set shape "robot with rock"
         ]
       
       ;; 1) Now count the yellow patches (rocks) around the robot.
       ;; If that number is greater than or equal to 2, the robot
       ;; asks itself to set usingPheromone? to true.
       if count patches in-radius 1 with [pcolor = yellow] >= 2[
         ask myself [set usingPheromone? true]
       ]
     ]
   ]     
   
       
 end   
 
 ;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;
 ;; return-to-base ;;
 ;;;;;;;;;;;;;;;;;;;;
 
 to return-to-base
 ;; If the patch color is green, we found the base.
 ifelse pcolor = green
   
 ;; Change the robot's shape to the one without the rock,
 ;; and start searching again. 
  [
  set shape "robot"
  set returning? false
  set searching? true
  
 ;; 2) Set pheromone detection on with probability equal to the slider value.
 ;; If detection is activated, turn on pheromone, turn off searching, and
 ;; check-for-trails.
  set usingPheromone? false
  if random 100 < percentChanceToFollowPheromone[
    set usingPheromone? true
    set searching? false
    check-for-trails
  ]
  ]
                             
 ;; Else, we didn't find the base yet--face the base.
  [
    facexy 0 0 
    
    ;;  1) Lay a pheromone trail back to the base if we are using pheromone.
    ;;  Other robots can pick it up.
    ;;  Be careful not to knock out rocks with the trail!
    ;;  Have the patch set its counter for how long the pheromone lasts.
    if usingPheromone? [
      ask patch-here[
        if pcolor != yellow [
        set pcolor cyan
        set pheromoneCounter pheromoneDuration
        ]
      ]
      ]
    ]
 end

 ;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;;;;;
 ;; check-for-trails ;;
 ;;;;;;;;;;;;;;;;;;;;;;
 to check-for-trails
    
   ;; 1) Use an ifelse statement. 
   ;; Sense if there are any? trails near the robot (in-radius 2).
   ;; Robots cannot sense the faintest trails, so only check for the strongest and slightly evaporated trails:
   ;; these trails have color cyan or cyan - 10.
   ifelse any? patches in-radius 2 with [(pcolor = cyan) or (pcolor = cyan - 10)] 
   [ 
     ;; 2) If there is at least one patch that has a trail on it, create a variable called target to hold the one that's farthest
     ;; from the origin.
     let target one-of patches in-radius 2 with [(pcolor = cyan) or (pcolor = cyan - 10)] with-max [distancexy 0 0]
     
     ;; 3) Use a nested ifelse statement.
     ;; Compare the distance from the origin of the target patch to that of the robot.
     ;; If the patch is farther away than the origin than the robot, then set the robot's
     ;; label to "ph" to indicate that it's using pheromone.
     ifelse [distancexy 0 0] of target > [distancexy 0 0] of self [
       set label "ph"
       face target
     ]
     ;; 4) Else, the trail must be evaporating, or it is behind us. 
     ;; Call the sub procedure to take us back to search mode.
     [ switch-to-search-from-pheromone]
     ]
   ;; 5) There aren't any trails near us.
   ;; Call the sub-procedure to take us back to search mode. 
   [ switch-to-search-from-pheromone ]

 end
 
 ;; 6) Fill in the sub-procedure.
 ;------------------------------------------------------------------------------------
 to switch-to-search-from-pheromone
   
   ;; Turn off usingPheromone?
   set usingPheromone? false
   
   ;; Turn on searching?
   set searching? true
   
   ;; Set the label back to empty.
   set label ""
   
 end
@#$#@#$#@
GRAPHICS-WINDOW
307
10
920
644
100
100
3.0
1
14
1
1
1
0
0
0
1
-100
100
-100
100
0
0
1
ticks
30.0

BUTTON
122
11
188
44
setup
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
124
57
187
90
go
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
17
102
189
135
numberOfRobots
numberOfRobots
1
20
10
1
1
NIL
HORIZONTAL

SLIDER
19
206
191
239
singleRocks
singleRocks
0
100
55
5
1
NIL
HORIZONTAL

SLIDER
20
248
192
281
clusterRocks
clusterRocks
0
50
37
1
1
NIL
HORIZONTAL

SLIDER
18
143
190
176
maxAngle
maxAngle
0
90
20
5
1
NIL
HORIZONTAL

MONITOR
74
466
187
511
rocks remaining
count patches with [pcolor = yellow]
17
1
11

SLIDER
12
355
191
388
pheromoneDuration
pheromoneDuration
0
500
490
10
1
NIL
HORIZONTAL

SLIDER
22
298
194
331
largeClusterRocks
largeClusterRocks
0
10
10
1
1
NIL
HORIZONTAL

SLIDER
14
407
286
440
percentChanceToFollowPheromone
percentChanceToFollowPheromone
0
100
72
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

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

robot
true
1
Polygon -16777216 true false 75 60 105 15 135 15 90 75 75 60
Polygon -16777216 true false 225 60 195 15 165 15 210 75 225 60
Rectangle -16777216 true false 30 105 75 165
Rectangle -16777216 true false 30 210 75 270
Rectangle -16777216 true false 75 120 225 255
Rectangle -16777216 true false 225 210 270 270
Rectangle -16777216 true false 225 105 270 165
Rectangle -16777216 true false 90 120 210 195
Rectangle -2674135 true true 120 120 180 240
Rectangle -16777216 true false 195 225 210 240
Rectangle -16777216 true false 120 60 180 90
Rectangle -16777216 true false 135 90 165 120
Polygon -2674135 true true 180 75 210 90 210 105 180 90 180 75
Polygon -2674135 true true 120 75 90 90 90 105 120 90 120 75
Rectangle -7500403 true false 75 105 225 120
Line -2674135 true 90 120 90 240
Line -2674135 true 210 120 210 240
Line -2674135 true 135 90 165 90
Line -16777216 false 75 165 225 165
Line -16777216 false 75 180 225 180
Rectangle -7500403 true false 75 240 225 255

robot with rock
true
1
Rectangle -1184463 true false 120 0 180 45
Polygon -16777216 true false 75 60 105 15 135 15 90 75 75 60
Polygon -16777216 true false 225 60 195 15 165 15 210 75 225 60
Rectangle -16777216 true false 30 105 75 165
Rectangle -16777216 true false 30 210 75 270
Rectangle -16777216 true false 75 120 225 255
Rectangle -16777216 true false 225 210 270 270
Rectangle -16777216 true false 225 105 270 165
Rectangle -16777216 true false 90 120 210 195
Rectangle -2674135 true true 120 120 180 240
Rectangle -16777216 true false 120 60 180 90
Rectangle -16777216 true false 135 90 165 120
Polygon -2674135 true true 180 75 210 90 210 105 180 90 180 75
Polygon -2674135 true true 120 75 90 90 90 105 120 90 120 75
Rectangle -7500403 true false 75 105 225 120
Line -2674135 true 75 240 225 240
Line -2674135 true 90 120 90 240
Line -2674135 true 210 120 210 240
Line -2674135 true 135 90 165 90
Line -16777216 false 75 165 225 165
Line -16777216 false 75 180 225 180
Rectangle -7500403 true false 75 240 225 255

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
NetLogo 5.2.0
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
0
@#$#@#$#@
