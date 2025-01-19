# Information About Object
a new array added to object file when using this lib, "scriptConfig"

## Exemple/Template
"scriptConfig" : {
    "type" : "processor",
    "autoRecipeSearch" : true,
    "startPaused" : false,
    "resources" : {
      "heat" : 0,
      "energy" : 0
    },
    "maxResources" : {
      "heat" : 60,
      "energy" : 500
    },
    "recipes" : "/shared/darkcraft8/machinery/V0_0_1/recipe/combustionGenerators.config",
    "slotConfig" : {
      "input" : [0],
      "buffer" : [],
      "output" : []
    },
    "node" : {
        "itemInput" : 0
        "resourceOutput" : 0
    },
    "recipeGroups" : [
      "primary",
      "secondary"
    ],
    "keepInventory" : true,
    "clearedResource" : [
      "energy"
    ],
    "transferTable" : [
        {
            "resource" : "energy",
            "count" : 1.02,
            "speed" : 0.017,
            "fillToMax" : true
        }
    ]
}

# The array parameters
"type"(string)
  handle what kind/type of logic to use for the object/machine.
"autoRecipeSearch"(boolean)
  as the name suggest determine if the machine should automaticaly search for the first valid recipes to craft.
"startPaused"(boolean)
  determine if the processor logic should start paused.

"resources" and "maxResources"(arrays of float/number)
  determine what kind and how much resources the object can contain and start with.
"recipes"(string or table)
  indicate the path to the recipes files.
"slotConfig"(arrays of table)
  indicate what slot are assigned to... currently none of the scripts use the buffer tables.

"node"(arrays)
  determine wish wire node is used for what. if note stated it default to the node n'0.
"recipeGroups"(table of string case sensitive)
  set of many and what kind of group/channel is used.
"keepInventory"(boolean)
  has the name suggest it determine if the object keep it inventory when picked up/destroyed.

"clearedResource"(table of string case sensitive)
  any resource named in this table will be reset when picked up.
"transferTable"(table of arrays)
  contain arrays that indicate what resource should be transfered to any valid connected object
  "resource"(string case sensitive)
    determine what resource it should be
  "count"(float)
    how much is sent
  "speed"(float/number)
    the interval at wish it is sent
  "fillToMax"(boolean)
    say if it should fill even if the target can't take all sent resources