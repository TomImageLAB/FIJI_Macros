// changelog May 2021
// Use DAPI to segment nuclei and determine cytoplasm as a ring of X microns around
// Use another marker (e.g. cytokeratin) to determine a compartment (nuclear and cytoplasmic)
// Quantify area and average intensity of another marker of interest in nuclear and cytoplasmic compartments

// Modifications wrt v2: - Calculation of total tissue area
//                       - Calculation of number of positive cells for the compartment marker, and number of
//                         positive cells for the marker of interest when thresholding is applied to this one

var prominence=0.15, cDAPI=1, cCompart=4, cMarker=5, cytoBand=5, minMarkerSize=3, thTissue=5;

macro "QIF Action Tool 1 - Cf00T2d15IT6d10m"{
	
	run("ROI Manager...");
	
	//just one file
	name=File.openDialog("Select File");
	//print(name);
	print("Processing "+name);
	
	Dialog.create("Parameters for the analysis");
	// Channels:
	Dialog.addMessage("Choose channel numbers")	
	Dialog.addNumber("DAPI", cDAPI);	
	Dialog.addNumber("Compartment marker", cCompart);	
	Dialog.addNumber("Marker for analysis", cMarker);
	// Tissue segmentation options:
	Dialog.addMessage("Choose threshold for tissue segmentation")	
	Dialog.addNumber("Tissue threshold", thTissue);	
	// Nuclei segmentation options:
	modeArray=newArray("Huang","Otsu","IsoData","Moments","Triangle","MaxEntropy","Minimum");
	Dialog.addMessage("Choose Nuclei Segmentation options")
	Dialog.addRadioButtonGroup("Methods", modeArray, 1, 7, "Otsu");
	Dialog.addNumber("Prominence for maxima detection", prominence);
	// Thresholding method for compartment:
	Dialog.addMessage("Choose the method for Compartment marker thresholding")
	Dialog.addRadioButtonGroup("Methods", modeArray, 1, 7, "Huang");
	Dialog.addMessage("Choose cytoplasm width")	
	Dialog.addNumber("Width (microns)", cytoBand);
	// Possibility of thresholding the marker of interest signal
	Dialog.addCheckbox("Threshold Marker of Interest and quantify only positive pixels", false);
	Dialog.addRadioButtonGroup("Thresholding method for marker of interest", modeArray, 1, 7, "Otsu");
	Dialog.addNumber("Min size of marker structures (px)", minMarkerSize);
	Dialog.show();	
	cDAPI= Dialog.getNumber();
	cCompart= Dialog.getNumber();
	cMarker= Dialog.getNumber();
	thTissue= Dialog.getNumber();
	thMethodNucl=Dialog.getRadioButton();
	prominence= Dialog.getNumber();
	thMethod=Dialog.getRadioButton();
	cytoBand= Dialog.getNumber();
	flagThMarker= Dialog.getCheckbox();
	thMethodMarker=Dialog.getRadioButton();
	minMarkerSize= Dialog.getNumber();

	//setBatchMode(true);
	qif("-","-",name,cDAPI,cCompart,cMarker,thTissue,thMethodNucl,prominence,cytoBand,thMethod,flagThMarker,thMethodMarker,minMarkerSize);
	setBatchMode(false);
	showMessage("QIF done!");

}

macro "QIF Action Tool 2 - C00fT0b11DT9b09iTcb09r"{
	
	run("ROI Manager...");
	
	InDir=getDirectory("Choose Tiles' directory");
	list=getFileList(InDir);
	L=lengthOf(list);

	Dialog.create("Parameters for the analysis");
	// Channels:
	Dialog.addMessage("Choose channel numbers")	
	Dialog.addNumber("DAPI", cDAPI);	
	Dialog.addNumber("Compartment marker", cCompart);	
	Dialog.addNumber("Marker for analysis", cMarker);
	// Tissue segmentation options:
	Dialog.addMessage("Choose threshold for tissue segmentation")	
	Dialog.addNumber("Tissue threshold", thTissue);
	// Nuclei segmentation options:
	modeArray=newArray("Huang","Otsu","IsoData","Moments","Triangle","MaxEntropy","Minimum");
	Dialog.addMessage("Choose Nuclei Segmentation options")
	Dialog.addRadioButtonGroup("Methods", modeArray, 1, 7, "Otsu");
	Dialog.addNumber("Prominence for maxima detection", prominence);
	// Thresholding method for compartment:
	Dialog.addMessage("Choose the method for Compartment marker thresholding")
	Dialog.addRadioButtonGroup("Methods", modeArray, 1, 7, "Huang");
	Dialog.addMessage("Choose cytoplasm width")	
	Dialog.addNumber("Width (microns)", cytoBand);
	// Possibility of thresholding the marker of interest signal
	Dialog.addCheckbox("Threshold Marker of Interest and quantify only positive pixels", false);
	Dialog.addRadioButtonGroup("Thresholding method for marker of interest", modeArray, 1, 7, "Otsu");
	Dialog.addNumber("Min size of marker structures (px)", minMarkerSize);
	Dialog.show();	
	cDAPI= Dialog.getNumber();
	cCompart= Dialog.getNumber();
	cMarker= Dialog.getNumber();
	thTissue= Dialog.getNumber();
	thMethodNucl=Dialog.getRadioButton();
	prominence= Dialog.getNumber();
	thMethod=Dialog.getRadioButton();
	cytoBand= Dialog.getNumber();
	flagThMarker= Dialog.getCheckbox();
	thMethodMarker=Dialog.getRadioButton();
	minMarkerSize= Dialog.getNumber();
	
	for (j=0; j<L; j++)
	{
		if(endsWith(list[j],"tif")){
			//analyze
			//d=InDir+list[j]t;
			name=list[j];
			print("Processing "+name);
			//setBatchMode(true);
			qif(InDir,InDir,list[j],cDAPI,cCompart,cMarker,thTissue,thMethodNucl,prominence,cytoBand,thMethod,flagThMarker,thMethodMarker,minMarkerSize);
			setBatchMode(false);
			}
	}
	
	showMessage("QIF done!");

}


function qif(output,InDir,name,cDAPI,cCompart,cMarker,thTissue,thMethodNucl,prominence,cytoBand,thMethod,flagThMarker,thMethodMarker,minMarkerSize)
{

run("Close All");

if (InDir=="-") {
	run("Bio-Formats Importer", "open="+name+" autoscale color_mode=Colorized rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");
	}
else {
	run("Bio-Formats Importer", "open="+InDir+name+" autoscale color_mode=Colorized rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_1");
	}	

//setBatchMode(true);

roiManager("Reset");
run("Clear Results");
MyTitle=getTitle();
output=getInfo("image.directory");

OutDir = output+File.separator+"AnalyzedImages";
File.makeDirectory(OutDir);

aa = split(MyTitle,".");
MyTitle_short = aa[0];

rename("orig");

getDimensions(width, height, channels, slices, frames);

// Create composite and merge only if we have less than 8 channels:
if (channels<8) {	
	Stack.setDisplayMode("composite");
	/*Stack.setChannel(1);
	run("Grays");
	Stack.setChannel(2);
	run("Green");
	Stack.setChannel(3);
	run("Blue");
	Stack.setChannel(4);
	run("Cyan");
	Stack.setChannel(5);
	run("Red");
	Stack.setChannel(6);
	run("Magenta");
	Stack.setDisplayMode("composite");
	Stack.setActiveChannels("1111110");
	wait(100);*/
	
	run("RGB Color");
	rename("merge");
}
else{
	selectWindow("orig");
	run("Duplicate...", "title=dapi duplicate channels="+cDAPI);
	selectWindow("orig");
	run("Duplicate...", "title=compart duplicate channels="+cCompart);
	selectWindow("orig");
	run("Duplicate...", "title=marker duplicate channels="+cMarker);
	run("Merge Channels...", "c1=marker c2=compart c3=dapi create");
	run("RGB Color");
	rename("merge");
	selectWindow("Composite");
	close();
}



run("Colors...", "foreground=black background=white selection=green");
run("Set Measurements...", "area mean redirect=None decimal=2");


waitForUser("1");



//--DETECT TISSUE

print("---- Segmenting tissue ----");
setBatchMode(true);
showStatus("Detecting tissue...");

if (channels>=8) {
	selectWindow("orig");
	run("Duplicate...", "title=tissue duplicate");
	run("8-bit");
	run("Subtract Background...", "rolling=200 stack");
	run("Gaussian Blur...", "sigma=4 stack");
	run("Threshold...");
		//thTissue=2;
	setThreshold(thTissue, 255);
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Default background=Dark");
		
}
selectWindow("merge");
run("Select All");
run("RGB to Luminance");
rename("a");
run("Subtract Background...", "rolling=200");
run("Gaussian Blur...", "sigma=4");
run("Threshold...");
	//thTissue=5;
setThreshold(thTissue, 255);
run("Convert to Mask");
run("Median...", "radius=12");
run("Analyze Particles...", "size=10000-Infinity pixel show=Masks in_situ");
run("Invert");
wait(100);
run("Analyze Particles...", "size=10000-Infinity pixel show=Masks in_situ");
run("Invert");
wait(100);
run("Create Selection");
run("Add to Manager");	// ROI0 --> whole tissue
selectWindow("a");
close();
setBatchMode(false);

selectWindow("merge");
roiManager("Select", 0);
run("Measure");
Atissue = getResult("Area", 0);
run("Clear Results");
roiManager("Set Color", "white");
roiManager("Set Line Width", 2);
run("Flatten");
wait(200);
selectWindow("merge");
close();
selectWindow("merge-1");
rename("merge");


// SEGMENT NUCLEI FROM DAPI:

selectWindow("orig");
run("Duplicate...", "title=nucleiMask duplicate channels="+cDAPI);
run("Mean...", "radius=3");
run("Subtract Background...", "rolling=300");
	// prominence=0.15
run("Find Maxima...", "prominence="+prominence+" output=[Single Points]");
rename("dapiMaxima");

selectWindow("nucleiMask");
//setAutoThreshold("Default dark");
//getThreshold(lower, upper);
	 //thDAPI=2.3;
//setThreshold(thDAPI, upper);
setAutoThreshold(thMethodNucl+" dark");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Median...", "radius=1");
run("Fill Holes");
run("Select All");
run("Analyze Particles...", "size=20-Infinity pixel show=Masks in_situ");

// Generate cellMask by enlarging the mask of nuclei
run("Duplicate...", "title=cellMask");
run("Create Selection");
	//cytoBand=5;
run("Enlarge...", "enlarge="+cytoBand);
setForegroundColor(0, 0, 0);
run("Fill", "slice");

selectWindow("dapiMaxima");
run("Select None");
run("Restore Selection");
setBackgroundColor(255, 255, 255);
run("Clear Outside");
run("Select None");

selectWindow("cellMask");
run("Select All");
run("Duplicate...", "title=cellEdges");
run("Find Edges");

// MARKER-CONTROLLED WATERSHED
run("Marker-controlled Watershed", "input=cellEdges marker=dapiMaxima mask=cellMask binary calculate use");

selectWindow("cellEdges-watershed");
run("8-bit");
setThreshold(1, 255);
setOption("BlackBackground", false);
run("Convert to Mask");
roiManager("Reset");
run("Analyze Particles...", "size=0-Infinity show=Masks add in_situ");
roiManager("Show None");

selectWindow("cellEdges");
close();
selectWindow("cellMask");
close();
selectWindow("dapiMaxima");
close();
selectWindow("cellEdges-watershed");
rename("cellMask");


// SEGMENT COMPARTMENT PIXELS

selectWindow("orig");
run("Duplicate...", "title=compartment duplicate channels="+cCompart);
setAutoThreshold(thMethod+" dark");
setOption("BlackBackground", false);
run("Convert to Mask");
run("Median...", "radius=1");
run("Analyze Particles...", "size=30-Infinity pixel show=Masks in_situ");


// CHECK ONE BY ONE WHICH CELLS ARE PART OF THE COMPARTMENT

n=roiManager("Count");
selectWindow("cellMask");
run("Select All");
setBackgroundColor(255, 255, 255);
run("Clear", "slice");
wait(100);

run("Clear Results");
selectWindow("compartment");
run("Select None");
roiManager("Deselect");
roiManager("Measure");
selectWindow("cellMask");	// fill in cellMask only nuclei positive por RNA
for (i=1; i<n; i++)
{
	Ii=getResult("Mean",i);	
	if (Ii!=0) {	//if there is RNA spot, negative cell --> delete ROI
  		roiManager("Select", i);
		run("Fill", "slice");
  	}  	 	
}
run("Select None");
roiManager("Reset");

//--Count number of cells in the compartment:
selectWindow("cellMask");
run("Select All");
run("Analyze Particles...", "size=30-Infinity pixel show=Masks display clear in_situ");
nCellsCompartment = nResults;

selectWindow("compartment");
close();

// GET NUCLEAR AND CYTOPLASMIC COMPARTMENTS

selectWindow("cellMask");
run("Select All");
run("Duplicate...", "title=cytoMask");

imageCalculator("AND", "nucleiMask","cellMask");
imageCalculator("XOR", "cytoMask","nucleiMask");


// PROCESS MARKER OF INTEREST

selectWindow("orig");
run("Select None");
run("Duplicate...", "title=marker duplicate channels="+cMarker);

flagNoMarkerPxNucl=false;
flagNoMarkerPxCyto=false;

//--If marker thresholding option is checked:
if(flagThMarker) 
{
	run("Duplicate...", "title=markerMask");
	setAutoThreshold(thMethodMarker+" dark");
	setOption("BlackBackground", false);
	run("Convert to Mask");
	
	//--AND between marker mask and compartment cell mask so that marker in individual cells is left and 
	// size filtering may be applied to detect positive cells with a certain no. of positive pixels
	imageCalculator("AND", "markerMask","cellMask");

	//run("Analyze Particles...", "size=3-Infinity pixel show=Masks in_situ");
	run("Analyze Particles...", "size="+minMarkerSize+"-Infinity pixel show=Masks in_situ");

	// DETECT MARKER-POSITIVE CELLS IN THE COMPARTMENT

	selectWindow("cellMask");
	roiManager("Reset");
	run("Analyze Particles...", "size=0-Infinity show=Masks add in_situ");
	roiManager("Show None");
	n=roiManager("Count");
	selectWindow("cellMask");
	run("Select All");
	setBackgroundColor(255, 255, 255);
	run("Clear", "slice");
	wait(100);

	run("Clear Results");
	selectWindow("markerMask");
	run("Select None");
	roiManager("Deselect");
	roiManager("Measure");
	selectWindow("cellMask");	// fill in cellMask with only marker-positive cells in the comparment
	for (i=1; i<n; i++)
	{
		Ii=getResult("Mean",i);	
		if (Ii!=0) {	
  			roiManager("Select", i);
			run("Fill", "slice");
  		}  	 	
	}
	run("Select None");
	roiManager("Reset");

	//--Count number of marker-positive cells in the compartment:
	selectWindow("cellMask");
	run("Select All");
	run("Analyze Particles...", "size=0-Infinity pixel show=Masks display clear in_situ");
	nCellsMarker = nResults;
	
	//--Save pixel ROIs for measurements:
	//--Nuclear compartment:
	selectWindow("nucleiMask");
	run("Create Selection");
	roiManager("Add");	// ROI 0 --> Nuclear compartment
	//--Cytoplasmic compartment:
	selectWindow("cytoMask");
	run("Create Selection");
	roiManager("Add");	// ROI 1 --> Cytoplasmic compartment
	//--Marker-positive pixels:
	selectWindow("markerMask");
	run("Create Selection");
	type=selectionType();
	if(type==-1) {
		makeRectangle(1,1,1,1);
		flagNoMarkerPxNucl=true;
		flagNoMarkerPxCyto=true;
	}
	roiManager("Add");	// ROI 2 --> Positive marker pixels
	close();
}
// If marker thresholding option is not checked:
else {

	nCellsMarker=NaN;
	//--Save pixel ROIs for measurements:
	//--Nuclear compartment:
	selectWindow("nucleiMask");
	run("Create Selection");
	roiManager("Add");	// ROI 0 --> Nuclear compartment
	//--Cytoplasmic compartment:
	selectWindow("cytoMask");
	run("Create Selection");
	roiManager("Add");	// ROI 1 --> Cytoplasmic compartment
	//--Marker pixels:
	run("Select All");
	roiManager("Add"); // ROI 2 --> Positive marker pixels (all pixels in this case)
}

selectWindow("nucleiMask");
close();
selectWindow("cytoMask");
close();


// MEASUREMENTS:

run("Clear Results");
run("Set Measurements...", "area mean standard integrated redirect=None decimal=2");
selectWindow("marker");
roiManager("Select", newArray(0,2));
roiManager("AND");
run("Measure");
type=selectionType();
if(type==-1) {
	flagNoMarkerPxNucl=true;	
}
roiManager("Deselect");
roiManager("Select", newArray(1,2));
roiManager("AND");
run("Measure");
type=selectionType();
if(type==-1) {
	flagNoMarkerPxCyto=true;	
}

Anucl=getResult("Area", 0);
Acyto=getResult("Area", 1);
IavgNucl=getResult("Mean", 0);
IavgCyto=getResult("Mean", 1);
IstdNucl=getResult("StdDev", 0);
IstdCyto=getResult("StdDev", 1);
ItotNucl=getResult("RawIntDen", 0);
ItotCyto=getResult("RawIntDen", 1);

// Aqua scores:
AquaScNucl = ItotNucl/Anucl;
AquaScCyto = ItotCyto/Acyto;

if(flagNoMarkerPxNucl) {
	Anucl=0;
	IavgNucl=0;
	IstdNucl=0;
	ItotNucl=0;
	AquaScNucl=0;
}
if(flagNoMarkerPxCyto) {
	Acyto=0;
	IavgCyto=0;
	IstdCyto=0;
	ItotCyto=0;
	AquaScCyto=0;
}

selectWindow("orig");
close();
selectWindow("marker");
close();


// Write results:
run("Clear Results");
if(File.exists(output+File.separator+"QIF_results.xls"))
{	
	//if exists add and modify
	open(output+File.separator+"QIF_results.xls");
	wait(500);
	IJ.renameResults("Results");
	wait(500);
}
i=nResults;
wait(100);
setResult("Label", i, MyTitle); 
setResult("Total tissue area (um2)", i, Atissue); 
setResult("# Cells in comparment", i, nCellsCompartment); 
setResult("# Marker-positive cells in comparment", i, nCellsMarker); 
setResult("Nuclear compartment area (um2)", i, Anucl); 
setResult("Cytoplasmic compartment area (um2)", i, Acyto); 
setResult("Nuclear compartment: Marker intensity avg", i, IavgNucl); 
setResult("Cytoplasmic compartment: Marker intensity avg", i, IavgCyto); 
setResult("Nuclear compartment: Marker intensity std", i, IstdNucl); 
setResult("Cytoplasmic compartment: Marker intensity std", i, IstdCyto); 
setResult("Nuclear compartment: AQUA score", i, AquaScNucl); 
setResult("Cytoplasmic compartment: AQUA score", i, AquaScCyto); 
saveAs("Results", output+File.separator+"QIF_results.xls");
	


// DRAW:

selectWindow("merge");
setBatchMode(false);
roiManager("Deselect");
run("Select None");
// Nuclear compartment:
run("Duplicate...", "title=nuclMask");
roiManager("Select", 0);
setForegroundColor(0, 0, 255);
run("Fill", "slice");
setBackgroundColor(0,0,0);
run("Clear Outside");
run("Select None");
// Cytoplasmic compartment:
selectWindow("merge");
run("Duplicate...", "title=cytoMask");
roiManager("Select", 1);
setForegroundColor(0, 255, 0);
run("Fill", "slice");
setBackgroundColor(0,0,0);
run("Clear Outside");
run("Select None");
// Positive marker pixels if it has been thresholded:
if(flagThMarker) {
	if (flagNoMarkerPxNucl & flagNoMarkerPxCyto)	// case of no marker signal in any compartment, create a black mask
	{
		selectWindow("merge");
		run("Duplicate...", "title=markerMask");
		run("Select All");
		setBackgroundColor(0,0,0);
		run("Clear");
		run("Select None");
	}
	else 
	{
		roiManager("Deselect");
		roiManager("Select", newArray(0,1));
		roiManager("Combine");
		roiManager("Add");
		roiManager("Deselect");
		roiManager("Select", newArray(2,3));
		roiManager("AND");
		roiManager("Add");
		roiManager("Deselect");
		roiManager("Select", newArray(2,3));
		roiManager("Delete");
		roiManager("Deselect");
		selectWindow("merge");
		run("Duplicate...", "title=markerMask");
		roiManager("Select", 2);
		setForegroundColor(255, 255, 0);
		run("Fill", "slice");
		setBackgroundColor(0,0,0);
		run("Clear Outside");
		run("Select None");
	}
}

// Add overlays:
selectWindow("merge");
run("Add Image...", "image=nuclMask x=0 y=0 opacity=25");
run("Add Image...", "image=cytoMask x=0 y=0 opacity=25");
if(flagThMarker) {
	run("Add Image...", "image=markerMask x=0 y=0 opacity=25");
}
run("Flatten");
selectWindow("merge-1");
if(flagThMarker) {
	selectWindow("cellMask");
	run("Create Selection");
	roiManager("Add");
	n=roiManager("count");
	selectWindow("merge-1");
	roiManager("Select", n-1);
	roiManager("Set Color", "magenta");
	roiManager("Set Line Width", 1);
	run("Flatten");
	selectWindow("merge-2");
}
saveAs("Jpeg", OutDir+File.separator+MyTitle_short+"_analyzed.jpg");
wait(100);
rename(MyTitle_short+"_analyzed.jpg");

if (InDir!="-") {
close(); }


selectWindow("nuclMask");
close();
selectWindow("cytoMask");
close();
selectWindow("cellMask");
close();
if(flagThMarker) {
	selectWindow("markerMask");
	close();
	selectWindow("merge-1");
	close();
}
selectWindow("merge");
close();

//showMessage("Done!");

}



