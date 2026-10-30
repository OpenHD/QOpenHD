.pragma library

function parse(text) {
    var parts=String(text).split(","), result=[]
    if(parts.length!==18)return []
    for(var i=0;i<18;i++) {
        if(!/^\d+$/.test(parts[i]))return []
        var value=Number(parts[i]);if(value<0||value>18)return []
        result.push(value)
    }
    return result
}
function assign(mapping, output, input) {
    var result=mapping.slice()
    if(output<0||output>=18||input<0||input>18||result.length!==18)return result
    if(input>0)for(var i=0;i<18;i++)if(i!==output&&result[i]===input)result[i]=0
    result[output]=input
    return result
}
function freeBlocks(mapping) {
    var result=[]
    if(mapping.length!==18)return result
    for(var base=5;base<=15;base++) {
        var free=true
        for(var j=0;j<4;j++)if(mapping[base-1+j]!==0)free=false
        if(free)result.push(base)
    }
    return result
}
function movedInput(baseline, values) {
    var found=-1, largest=250, runner=0
    for(var i=0;i<18;i++) {
        if(baseline[i]<800||baseline[i]>2200||values[i]<800||values[i]>2200)continue
        var delta=Math.abs(values[i]-baseline[i])
        if(delta>largest){runner=largest===250?0:largest;largest=delta;found=i}
        else if(delta>runner)runner=delta
    }
    return largest-runner>=100 ? found : -1
}
function sourceName(input) {
    return input===0 ? "Unassigned" : input<=8 ? "Axis "+input : "Button "+(input-8)
}
