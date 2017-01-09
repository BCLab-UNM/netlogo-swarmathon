;----------------------------------------------------------------------------------------------
 ;; INSTRUCTOR FILE
 ;----------------------------------------------------------------------------------------------

 ;; Elizabeth E. Esterly
 ;; elizabeth@cs.unm.edu
 ;; The University of New Mexico
 ;; Swarmathon 4: Advanced Deterministic Search
 ;; version 1.0
 ;; Last Revision 01/09/2017
 
  ;;1) use 2 breeds of robots: DFS-robots and spiral-robots
  breed [DFS-robots DFS-robot]
  breed [spiral-robots spiral-robot]
    
  
  ;;Update this from [Sw3] to be specific to DFS-robots.
  ;;DFS robots need to know:
  DFS-robots-own [
     ;;are they currently working with a list of rock locations? (in the processingList? state)
     processingList?     
     
     ;;are they currently returning to the base? (in the returning? state)
     returning?
     
     ;;store a list of rocks we have seen
     ;;rockLocations is a list of lists: [ [a b] [c d]...[y z] ]
     rockLocations
           
     ;;target coordinate x
     locX 
            
     ;;target coordinate y
     locY

     ;;what heading (direction they are facing in degrees) they start with
     initialHeading
    ]
  
  ;;2) spiral-robots need to know:
  spiral-robots-own[
  ]
  
  ;;patches need to know:
  patches-own [
     ;;base color before adding rocks
     baseColor
    ]  



;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;
 ;;    setup     ;; : MAIN PROCEDURE
 ;;;;;;;;;;;;;;;;;;
 ;------------------------------------------------------------------------------------
;Organize the code into main procedures and sub procedures.
to setup
  ca ;clear all
  cp ;clear patches
  reset-ticks ;keep track of simulation runtime
  
  ;setup calls these three sub procedures.
  make-robots
  make-rocks
  make-base
end

;This sub procedure has been completed for you.
;------------------------------------------------------------------------------------
to make-rocks
   if distribution = "cross" or distribution = "random + cross" 
   or distribution = "clusters + cross" or distribution = "random + clusters + cross" [make-cross]
   
   if distribution = "random + cross" 
   or distribution = "random + clusters + cross" [make-random]
   
   if distribution = "clusters + cross"
   or distribution = "random + clusters + cross" [make-clusters]
   
end

;Fill in the next two sub procedures.
;------------------------------------------------------------------------------------
;;1) Create the number of DFS-robots equal to the value of the numberOfDFSRobots slider.
;; Create the number of spiral-robots equal to the value of the numberOfSpiralRobots slider.
;; Set their properties and their variables that you defined previously.
;;This must be done separately.
to make-robots
  create-DFS-robots numberOfDFSRobots[
    set size 5
    set shape "robot"
    set processingList? false
    set returning? false
    set rockLocations []
    set locX 0
    set locY 0
    set initialHeading random 360
    set heading initialHeading
  ]
    
end

;------------------------------------------------------------------------------------
;;2) Place rocks in a cross formation.
to make-cross
  ask patches [
  ;;add some variation in the patches by adding a numerical value (color + random number)
    set pcolor black + random 3
  
    ;store color by setting baseColor variable before adding rocks
    set baseColor pcolor
                       
    ;;Set up the cross by taking the max coordinate value, doubling it, then only setting a rock if the
    ;;x or y coord is evenly divisible by that value. 
    ;;NOTE: This technique assumes a square layout.                  
    let doublemax max-pxcor * 2 
    if pxcor mod doublemax = 0 or pycor mod doublemax = 0 [ set pcolor yellow ] 
     
  ]                   
end

;------------------------------------------------------------------------------------
;Place rocks randomly.
to make-random
   let targetPatches singleRocks
     while [targetPatches > 0][
       ask one-of patches[
         if pcolor != black and pcolor != yellow[
           set pcolor yellow
           set targetPatches targetPatches - 1
         ]
       ]
     ]
end

;------------------------------------------------------------------------------------
;Place rocks in clusters.
to make-clusters
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
end

;------------------------------------------------------------------------------------
;Make a base at the origin.
to make-base
  ask patches[
    if distancexy 0 0 < 4 [set pcolor green]
  ]
  
end

;MAIN
to main
  ask DFS-robots[DFS]
  ask spiral-robots[fd 1]
   tick ;;tick must be called from observer context, move into main procedure.
end

;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;
 ;;    DFS      ;; : MAIN PROCEDURE
 ;;;;;;;;;;;;;;;;;
 ;------------------------------------------------------------------------------------

;;Write the DFS procedure.
to DFS 
  
  ;;1) Put the exit condition first. Stop when no yellow patches (rocks) remain.
  if count patches with [pcolor = yellow] = 0 [stop] 
  
  ;;All sub procedures called after this (set-direction, do-DFS, process-list) are within the ask robots block.
  ;;So, the procedures act as if they are already in ask robots.
  ;;That means that when you write the sub procedures, you don't need to repeat the ask robots command.
  
  ;;2)
  ask DFS-robots[
      
   ;;If the robot can't move, it must've reached a boundary.
   if not can-move? 1[
     ;;Add the last rock to our list if we're standing on it by calling do-DFS.
     do-DFS
              
     ;;If there's anything in our list, turn on the processingList? status.
     ifelse not empty? rockLocations
     [set processingList? true]
                 
     ;;else go home to reset our search angle.
     [set returning? true]            
   ]
     
   ;;3) Main control of the procedure goes here in an ifelse statement.   
   ;;Check if we are in the processing list state and not returning. If we are, then process the list.
   ;;(While we are processing, we'll also sometimes be in the returning? state
   ;;at the same time when we're dropping off rocks.
   ;;Robots should only process the list though when they're not dropping off a rock.
      if processingList? and not returning? [process-list]
   
   ;;If returning mode is on, the robots should return-to-base.
      if returning? [return-to-base]
   
   ;;Else, if the robots are not processing a list and not returning, they should do DFS.
      if not processingList? and not returning? [do-DFS]
   
   
  ]
 
end

;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;;
 ;; process-list ;; : MAIN PROCEDURE
 ;;;;;;;;;;;;;;;;;;
;------------------------------------------------------------------------------------
;;Write the process-list procedure.
to process-list
  
  ;;1) Control the robots based on the status of their internal list of rocks.
  ;;If the robot's list is not empty:
  ifelse not empty? rockLocations[
    
  ;;2) ;If locX and locY are set to 0, then we just started or we just dropped off a rock.
    if locX = 0 and locY = 0 [
    
    ;;If they are, then we need a new destination, so reset our target coordinates, locX and locY.
    ;;We'll write the code for that in a sub procedure, so just call the procedure for now. 
      reset-target-coords
    ]
   
    ;;Now move-to-location of locX locY.
    ;;We'll write the code for that in a sub procedure, so just call the procedure for now. 
    move-to-location
  ]
  
  ;;3) rockLocations is empty. We're done processing the list.
  [set processingList? false]

  ;;Go forward 1 step.
  fd 1
  
end

;;Fill in sub procedures.
;------------------------------------------------------------------------------------ 
;;1) Reset the robot's target coordinates when they are still processing the list but 
;;have just dropped off a rock and don't know where to go.
;;Recall that rockLocations is a list of lists: [ [a b] [c d]...[y z] ]
to reset-target-coords
 
  ;;if rockLocations is not empty
  if not empty? rockLocations[
  
       ;;Grab the first element of rockLocations, a list of 2 coordinates: [a b]
       let loc first rockLocations
       
       ;;Now set robots-own x to the first element of this [a _]
       set locX first loc
       
       ;;and robots-own y to the last. [_ b]
       set locY last loc
       
       ;;and keep everything but the first list of coords (the ones we just used) 
       ;;in rockLocations. --> [ [c d]...[y z] ]
       set rockLocations but-first rockLocations
  ]
       
end
;------------------------------------------------------------------------------------

;;2) The robot arrived at its locX locY. Pick up the rock and set the robot's mode
;;to returning so it can drop off the rock. Remain in processing state so the robot goes
;;back to processing the list after dropping off the rock.
to move-to-location
  
  ;;If we've reached our target coordinates locX and locY,
  ifelse (pxcor = locX and pycor = locY)[
  
       ;; pick up the rock by setting the robot's shape to the one holding the rock,
       set shape "robot with rock"
       
       ;; and ask the patch-here to return to its base color.
       ask patch-here[ set pcolor baseColor]
       
       ;; Turn on returning? mode.
       set returning? true
  ]
       
  ;Else the robot has not arrived yet; face the target location.
  [facexy locX locY]
  
 end

;------------------------------------------------------------------------------------
 ;;3) We've used the return-to-base procedure many times.
 ;;This time, we'll make some changes to support list processing.
 to return-to-base
   
 ;; If we're at the origin, we found the base.
 ifelse pcolor = green[ 
    
 ;; Change the robot's shape to the one without the rock.
   set shape "robot"
 
 ;; We've arrived, so turn off returning? mode.
   set returning? false
 
 ;; set locX 
   set locX 0
 
 ;; and locY to 0. Robots will return to base if they don't find anything.
   set locY 0
  
  ;;Use an if statement. A robot can also be here if it has finished processing a list
  ;;of if it didn't find anything at the current angle and was sent back to base. 
  ;;If this happened, change its heading so it searches in a different direction.
  ;;It will begin to search +searchAngle degrees from its last heading.
   if not processingList?[
     set initialHeading initialHeading + searchAngle
     set heading initialHeading
   ]
 ]
                        
 ;; Else, we didn't find the origin yet--face the origin.
 [ facexy 0 0 ]
 
 ;; Go forward 1.
 fd 1
 
 end

;------------------------------------------------------------------------------------
 ;;;;;;;;;;;;;;;;;
 ;; do-DFS      ;; : MAIN PROCEDURE
 ;;;;;;;;;;;;;;;;;
 ;------------------------------------------------------------------------------------
;;Write the do-DFS procedure. do-DFS finds rocks and stores them in a list. 
to do-DFS
 
  ;;1) ask the patch-here
  ask patch-here[
  
     ;;if its pcolor is yellow,
     if pcolor = yellow[
     
      ;;make a list of the coords of the rock we're on.
      let location (list pxcor pycor)
     
          ;;to add those coordinates to the front of their list of rocklocations and remove any duplicates.
         ask myself[ set rockLocations remove-duplicates (fput location rockLocations)]

     ]
  ]

  ;;Go forward 1.
  fd 1
  
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
725
546
50
50
5.0
1
10
1
1
1
0
0
0
1
-50
50
-50
50
0
0
1
ticks
5.0

BUTTON
128
12
195
46
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
129
64
193
98
main
main
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
83
114
197
159
rocks remaining
count patches with [pcolor = yellow]
17
1
11

CHOOSER
10
170
198
215
distribution
distribution
"cross" "random" "clusters" "clusters + cross" "random + clusters" "random + cross" "random + clusters + cross"
6

SLIDER
10
225
182
258
singleRocks
singleRocks
0
100
100
5
1
NIL
HORIZONTAL

SLIDER
11
268
183
301
clusterRocks
clusterRocks
0
50
50
5
1
NIL
HORIZONTAL

SLIDER
18
318
193
351
numberOfDFSRobots
numberOfDFSRobots
1
10
6
1
1
NIL
HORIZONTAL

SLIDER
18
366
190
399
searchAngle
searchAngle
5
90
5
5
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
