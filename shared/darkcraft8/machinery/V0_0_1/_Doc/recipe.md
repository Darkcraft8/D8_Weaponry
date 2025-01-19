# Information About Recipe Config
recipes used by processor object (generator,fabricator,processor) are similar but not identical to vanilla recipe and don't care about unlock's
recipes file are table containing arrays that are the individual recipe

## Parameters
"priority"(float/number)
  work the same way as mod priority
  
## The input tables can take 3 type of input
item
resource
currency

## The output tables can take 4 type of input
item
resource
currency
treasure


# Exemple/Template
item : {
    item : "coalOre",
    count : 1
}
resource : {
    resource : "energy",
    count : 1
}
currency : {
    currency : "money",
    count : 1
}
treasure : {
    currency : "money",
    count : 1,
    level : 1,
    seed  : nil
}

# Group
group work differently compared to vanilla recipes. They are used to determine in what "channel" of recipes it belong to.
these can be used to allow machine to multitask recipes
group always default to "primary" when not stated otherwhise

# Fill Recipes
fill recipes are a bit different in the sense that they try to fill a valid output item parameters instead of create a new one
the outputs table become the targetTable
a new array get introduced with these kind of recipes the amount array
the amount array determine the amount increased of the listed parameters
ex: {
    "fill" : true,
    "inputs" : [
        {
            "resource" : "oxygen",
            "count" : 1
        }
    ],
    "duration" : 0.025,
    "amount" : {
        "resourceAmount" : 1,
        "durabilityHit" : 1
    },
    "outputs" : [
        {
            "item" : "d8Weaponry_gascanister",
            "count" : 1,
            "parameters" : {
                "resourceKind" : "oxygen",
                "resourceAmount" : 125,
                "resourceMax" : 125,

                "durability" : 126,
                "durabilityHit" : 125,

                "buildConfig" : {
                    "resourcePath" : {
                        "resource1Amount" : "resourceAmount",
                        "resource1MaxAmount" : "resourceMax"
                    },
                    "resource1Label" : "Oxygen"
                }
            }
        }
    ],
    "group" : "secondary"
}