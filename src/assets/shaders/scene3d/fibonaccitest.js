
var MathTAU = Math.PI * 2.0;

function WrapIntoMinusPIToPI(x){
  x = (x + Math.PI) % MathTAU;
  return (x - Math.PI) + ((x < 0.0) ? MathTAU : 0.0);
//return ((((x + Math.PI) % MathTAU) + MathTAU) % MathTAU) - Math.PI;
}

// Test case if both Phi calculation methods are equal enough for our purposes for the first x values,
// when using the golden ratio based method and the golden angle based method, and when both are
// wrapped into the range of -PI to PI. 
var count = 1000000;
var differences = false;
for(var i = 0; i < count; i++){
  var phiValues = [
    WrapIntoMinusPIToPI(((i * 0.61803398874989485) % 1.0) * MathTAU), // Golden ratio based
    WrapIntoMinusPIToPI(i * -2.39996322972865332)                     // Golden angle based, negative to match the golden ratio based method
  ];
  if(Math.abs(phiValues[0] - phiValues[1]) > 1e-8){
    console.log("Phi values are too different for i = " + i, " phiValues[0] = " + phiValues[0], " phiValues[1] = " + phiValues[1]); 
    differences = true;
    break;
  }
}
if(!differences){
  console.log("Phi calculation methods are equal enough for a fibonacci sphere for the first " + count + " values");
}else{
  console.log("Phi calculation methods are not equal enough for a fibonacci sphere for the first " + count + " values");
}