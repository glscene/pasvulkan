// Generated by ssao_gensamples.poca
#ifndef SSAO_SAMPLES_GLSL
#define SSAO_SAMPLES_GLSL
#if NUM_SAMPLES == 16
const int countKernelSamples = 16;
const vec3 kernelSamples[16] = vec3[16](
  vec3(-0.7249891466933509, -0.04272272122724784, 0.22367577340380473),
  vec3(-0.12929094728938428, 0.18179302452873036, 0.5111772505147947),
  vec3(-0.08513634670413565, 0.7676187291205127, 0.37558372064165196),
  vec3(0.663444380636299, 0.02707560666878247, 0.08339122008950076),
  vec3(-0.8880657040289935, 0.31083860141962333, 0.4798901418213018),
  vec3(-0.014001679598174365, -0.34769319956650657, 0.13375158504261844),
  vec3(0.5603310586108798, -0.18411540444610994, 0.5006185047959958),
  vec3(-0.31682119062079594, -0.6436859064563117, 0.2371089806278971),
  vec3(0.25559530378452394, -0.3884658833253463, 0.5732075190823637),
  vec3(-0.539320370782472, 0.6287840883113197, 0.3215117104436863),
  vec3(0.26825492177566795, 0.11079527867313774, 0.3189702682337363),
  vec3(-0.4406576271633768, -0.5671848033814325, 0.09801977169520912),
  vec3(0.11328854663347486, -0.27861235733156975, 0.38813541482456776),
  vec3(0.399455871720153, 0.6823682627277475, 0.17097335760465177),
  vec3(0.8215723706353841, 0.22283315329171624, 0.26331935045223015),
  vec3(-0.07961402408518768, -0.1931373343365287, 0.2590395445902197)
);
#elif NUM_SAMPLES == 32
const int countKernelSamples = 32;
const vec3 kernelSamples[32] = vec3[32](
  vec3(-0.6809720820254094, -0.08591360705772068, 0.22270837931603354),
  vec3(-0.09393044352006216, 0.1434799050721074, 0.5122804612734201),
  vec3(-0.04280665820109259, 0.7144682063017123, 0.3721270072629318),
  vec3(0.7365394833337583, -0.01563819086501558, 0.08502954753763493),
  vec3(-0.8330049228123659, 0.25865090243215566, 0.47487721572855435),
  vec3(0.019240070915080284, -0.40223989794252446, 0.13800634790333194),
  vec3(0.6307050803195469, -0.23916969615499203, 0.5233237947983845),
  vec3(-0.2867021908070803, -0.7120491855093326, 0.2438605422361616),
  vec3(0.3094211803055248, -0.4523863950426083, 0.5989379275564257),
  vec3(-0.4872173371577087, 0.5713521991472658, 0.31624553562833585),
  vec3(0.3113469647983118, 0.0772956021600652, 0.3278720339896669),
  vec3(-0.41234270464912337, -0.627637420513608, 0.09938314213302774),
  vec3(0.15486531340525153, -0.33141324069495903, 0.40473520718985234),
  vec3(0.44453616792709444, 0.6432759691136495, 0.17204387354230222),
  vec3(0.8980948006674104, 0.18352972064364825, 0.2717011165076124),
  vec3(-0.05022695741076336, -0.2344475105888303, 0.2660571349250746),
  vec3(0.5485349548994346, -0.048786816442344894, 0.7073528918225498),
  vec3(0.000999486385938502, 0.17725876484845435, 0.09663203682234281),
  vec3(0.6401110086345183, 0.5358789263230486, 0.5021519460898831),
  vec3(-0.7228906812399724, -0.22837156439834155, 0.1851078568110292),
  vec3(-0.10817943907615626, 0.021244137813359657, 0.45731950147141903),
  vec3(-0.28974725386379047, -0.394226910648177, 0.24482653843065538),
  vec3(0.245427265025145, -0.17807833684727545, 0.5839683434876605),
  vec3(-0.4111038351711394, 0.08133483166910507, 0.055892614603300986),
  vec3(0.08044746188291284, 0.2936105043208719, 0.3524031530206448),
  vec3(0.30217287933242526, -0.3136333315742313, 0.11568401373971625),
  vec3(-0.6287916678381176, -0.1197222198204873, 0.48446252666520245),
  vec3(-0.03597437627864464, 0.13736079572223378, 0.8565137465881615),
  vec3(0.1798074778117941, 0.9928890217925673, 0.21541882758735076),
  vec3(0.025119282769137326, 0.35246460297718957, 0.24241220635291943),
  vec3(-0.2723503806552118, 0.20889404783744203, 0.7010911738104736),
  vec3(-0.0791949693372522, -0.7682962371032197, 0.07135792190403956)
);
#elif NUM_SAMPLES == 64
const int countKernelSamples = 64;
const vec3 kernelSamples[64] = vec3[64](
  vec3(-0.7217256363654584, -0.12161551378182685, 0.23002048270658576),
  vec3(-0.10689155680273604, 0.11910382072596759, 0.524513080322403),
  vec3(-0.05526867757196581, 0.690205965114912, 0.3757198426270702),
  vec3(0.7419372820493717, -0.04793292596817705, 0.08585088895582366),
  vec3(-0.8732432714248539, 0.23152951216517562, 0.4886653147238076),
  vec3(0.01003465222694878, -0.45125173249295175, 0.142708264217925),
  vec3(0.6381477366294, -0.2801558525576221, 0.5382427882716582),
  vec3(-0.3147793304080481, -0.7843602875940904, 0.2543712407509257),
  vec3(0.3098608401929877, -0.5040477812896929, 0.6215203628409145),
  vec3(-0.509296001394706, 0.5502923947571797, 0.3216673393339955),
  vec3(0.30794444981848684, 0.05204875455952639, 0.33375688361566214),
  vec3(-0.4471504319549538, -0.6949971994650478, 0.10207658157191137),
  vec3(0.15094126007740674, -0.3749757495926827, 0.42039167660417504),
  vec3(0.43617165035537475, 0.6162849019554556, 0.17303740262209172),
  vec3(0.9026414038245217, 0.15239254225345983, 0.2760088795314866),
  vec3(-0.06224942911520573, -0.2715478667651791, 0.2764229189948279),
  vec3(0.5509902008481998, -0.08391221169700679, 0.725351750913985),
  vec3(-0.007843741905260349, 0.15956346767123547, 0.09825814799980201),
  vec3(0.6359574969061332, 0.5085795314327541, 0.5083029636922579),
  vec3(-0.7683305804503288, -0.2719520132130799, 0.19129918565807186),
  vec3(-0.12181613365461363, -0.005207234063772445, 0.47065786397799564),
  vec3(-0.31626128560343736, -0.4448708297578699, 0.2552822092559334),
  vec3(0.2426772826443903, -0.2146548709164734, 0.6025593946218349),
  vec3(-0.43585511584848696, 0.05705860443959778, 0.056102560217578826),
  vec3(0.07162940663345668, 0.27098880473478376, 0.35668289948793197),
  vec3(0.304628189327661, -0.35458915488577836, 0.11845760736244552),
  vec3(-0.6672555684497462, -0.15774245202784096, 0.5025516887452067),
  vec3(-0.04934987789765957, 0.10794885401933409, 0.879112529617018),
  vec3(0.16828848901953616, 0.9665627019942528, 0.21692991406490025),
  vec3(0.015637022140997738, 0.3301280820169708, 0.2445495746694376),
  vec3(-0.29192502447977253, 0.18271588122150315, 0.7193962302116155),
  vec3(-0.0959232560270133, -0.843439750753086, 0.07251771287142811),
  vec3(0.5392326435676047, -0.5858714547410218, 0.4550724464401547),
  vec3(-0.24721228456669456, 0.8049905056964756, 0.5476120458625945),
  vec3(0.5151649926928276, -0.0008085966344398508, 0.19845716594260127),
  vec3(-0.4164914759483354, 0.25090594359355595, 0.5646569868606712),
  vec3(0.37610161173622597, -0.1886050979260654, 0.20585414062348129),
  vec3(-0.5688678401347926, 0.036486119327419, 0.6027791686705058),
  vec3(0.24609328849962261, -0.7126862047883255, 0.3099221024944138),
  vec3(0.0979603432312316, -0.11122583017701643, 0.07925080175229665),
  vec3(0.7738878649010387, 0.11584033698487071, 0.47274016532048135),
  vec3(-0.003179462021056719, -0.6309517241611508, 0.529086424472076),
  vec3(0.6575718869074358, 0.18632773473656247, 0.3168573302954116),
  vec3(-0.35702421726678135, 0.4723725355370714, 0.717744493696516),
  vec3(-0.264469785217961, -0.2495607061969274, 0.3441649435326161),
  vec3(0.29465125779573953, -0.0325523509264001, 0.7548201398890043),
  vec3(0.540479945817086, 0.8099338961143983, 0.1083910128780759),
  vec3(-0.1857313650041172, 0.2022245242032323, 0.1468863592880313),
  vec3(0.37050590607686973, 0.5340071803130538, 0.5496668628859752),
  vec3(0.11868794842542825, 0.030504423644413938, 0.20718334028391172),
  vec3(-0.5818405356484889, -0.44282174121932866, 0.3378079434994707),
  vec3(0.024982464168500775, -0.16902880746778656, 0.6567133463356876),
  vec3(-0.658447594904113, 0.11017296219755279, 0.11509393999115375),
  vec3(-0.07450575311224662, 0.3273183133550384, 0.4266215062142745),
  vec3(-0.23923307392153786, -0.11044030995994489, 0.9936728629122772),
  vec3(-0.13208366282906453, 0.39327403030680846, 0.3102675934100972),
  vec3(0.6287339687437867, -0.2755226475326509, 0.05976934804971622),
  vec3(-0.2961373079307771, -0.022880977602217252, 0.36199223594739727),
  vec3(0.257601328346067, 0.23820819693830683, 0.8061289679769509),
  vec3(-0.27267791981908807, -0.7917226428995988, 0.13530010040212037),
  vec3(0.3370635536084081, -0.503866606739541, 0.491356956438921),
  vec3(-0.4503860937367272, 0.5102855033447784, 0.20008185926165994),
  vec3(-0.5782230436757411, 0.29455911466356854, 0.28341777928361184),
  vec3(0.004485232691286892, 0.5871661197864392, 0.6789202007742754)
);
#endif
#endif