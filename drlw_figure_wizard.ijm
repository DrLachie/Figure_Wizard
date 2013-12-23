run("Bio-Formats Macro Extensions"); //for various reasons

//Global variables - DO NOT REMOVE

var nCHANNELS = 1;
var nPANELS = 4;
var EXP_TITLE = "Dummy_Filename";
var DO_MONTAGE = true;
var MAIN_ROI_SIZE = 200;
var DO_INSET = false;
var INSET_ROI_SIZE = 40;
var DO_DIC_INSET = false;
var DO_BURN_FILENAME = false;
var DO_SCALEBAR = true;
var SCALEBAR_SIZE = 1;
var CLOSE_ALL_AT_END = false;
var PANEL1 = "C1";
var PANEL2 = "C2";
var PANEL3 = "C1+C2+C3";
var PANEL4 = "C4";
var C1_STRING="Green";
var C2_STRING="Red";
var C3_STRING="Blue";
var C4_STRING="DummyGrays";


var fs = File.separator();



//At the moment, just runs on a single file that you open here
//eventually I'll put the batch processing in - I have the code for that elsewhere
//it's just made slightly more complicated by the different options available here
fpath=File.openDialog("Select a file");

//Check that the file is ok to use. 
Ext.isThisType(fpath, thisType)
if(thisType=="true"){
	Ext.setId(fpath);
	Ext.getSizeC(nCHANNELS);
	print(nCHANNELS+ " channels in " + fpath);
}else{
	showStatus("Why are you looking up here?");s
	exit("Fatal Error - Not a supported file format\n\nExiting macro");
}

//Check for existing config file
config_fpath = File.getParent(fpath);
config_fpath = config_fpath + fs + "config.txt";

if(File.exists(config_fpath)){
	use_old_config = getBoolean("Config file exists, re-use these settings?");
	if(use_old_config){
		read_config(config_fpath);
	}else{
		setup_config(fpath);
	}
}else{
	setup_config(fpath);
}


//Open the image (using bioformats) 
run("Bio-Formats Importer", "open=["+fpath+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
fname = getInfo("image.filename");

//Show middle slice, (change to find middle slice)
getDimensions(width,height,channels,slices,frames);

DIC_Channel = Get_Channel("Grays");
print(DIC_Channel);
if(DIC_Channel>=0){
	Stack.setPosition(DIC_Channel, slices/2, 1);
}else{
	//If theres no DIC just find the thing on channel 1
	Stack.setPosition(1, slices/2, 1);
}
makeRectangle(width/2 - MAIN_ROI_SIZE/2, height/2 - MAIN_ROI_SIZE/2, MAIN_ROI_SIZE, MAIN_ROI_SIZE);
//waitForUser("Main ROI", "Move the ROI to wherever you want it") ;
run("Duplicate...", "title=Allz_Allc_LargeROI duplicate");//channels=1-4 slices=1-30");
close(fname);
		

Green_Channel = Get_Channel("Green");
if(Green_Channel>=0){
	Stack.setPosition(Green_Channel, slices/2, 1);
}else{
	//If theres no Green just find the thing on channel 1
	Stack.setPosition(1, slices/2, 1);
}
//waitForUser("Select Plane", "Select \"Best\" Plane") ;
		
Stack.getPosition(channel,best_slice,time); 
run("Duplicate...", "title=1z_Allc_LargeROI duplicate channels=1-4 slices="+best_slice);


make_panel(PANEL1,"1z_Allc_LargeROI",1);
if(nPANELS>1){make_panel(PANEL2,"1z_Allc_LargeROI",2);}
if(nPANELS>2){make_panel(PANEL3,"1z_Allc_LargeROI",3);}
if(nPANELS>3){make_panel(PANEL4,"1z_Allc_LargeROI",4);}

if(DO_SCALEBAR){
	selectWindow("Panel_"+nPANELS);
	run("Scale Bar...", "width=1 height=4 font=14 color=White background=None location=[Lower Right] hide");
//	print("Doin' a scalebar");
}

combine_panels_and_montage();

if(DO_BURN_FILENAME){
	EXP_TITLE = fname;
	setForegroundColor(200,200,200); //Adjust Caption color
	setFont("SansSerif", 18, "bold"); //adjust to change appearance of caption ("bold" can be removed and "SansSerif" can be changed to "Serif");
	xpos=10;ypos=35; //adjust these to move the caption around
	caption=EXP_TITLE;
	drawString(caption,xpos,ypos);
}



/* *************************************************************************
 * 
 *  	FUNCTIONS
 * 
 * 
 * *************************************************************************
 */

 function Channel_Setup_Menu(number_of_channels){

	print("number_of_channels = " + number_of_channels);
	choiceArray = newArray("Red", "Green", "Blue", "Grays", "NA"); 	
 	Dialog.create("Initial Setup");
 	Dialog.addMessage("Setup channel numbers and colours nb: Grays==DIC");
 	
	Dialog.addChoice("Channel 1",choiceArray,"Green");
	
	Dialog.addChoice("Channel 2",choiceArray,"Red");
	Dialog.addChoice("Channel 3",choiceArray,"Blue");
	if(number_of_channels == 4){
		Dialog.addChoice("Channel 4",choiceArray,"Grays");
	}

	Dialog.addNumber("Number of montage panels",4,0,2,"");
		
	Dialog.show();

	C1_STRING=Dialog.getChoice();
	C2_STRING=Dialog.getChoice();
	C3_STRING=Dialog.getChoice();
	if(number_of_channels == 4){
		C4_STRING=Dialog.getChoice();
	}
	nPANELS = Dialog.getNumber();
	Dialog.addHelp("http://en.wikipedia.org/wiki/Special:Random");
}

  function Panel_Setup_Menu(number_of_panels,number_of_channels){

	if(nImages==1){
		fname=getInfo("image.filename");
	}else{
		fname="Dummy_Filename";
	}


	if(number_of_channels==4){
		panel_choices = newArray("C1","C2","C3","C4","C1+C2","C1+C2","C1+C3","C1+C4","C2+C4","C3+C4","C1+C2+C3","C1+C2+C4","C2+C3+C4","C1+C2+C3+C4");
	}
	if(number_of_channels==3){
		panel_choices = newArray("C1","C2","C3","C1+C2","C1+C2","C1+C3","C1+C2+C3");
	}
	if(number_of_channels==2){
		panel_choices = newArray("C1","C2","C1+C2");
	}
	
	
  	Dialog.create("Panel Setup");
 	
	Dialog.addString("Experiment Title:", fname, 25);
  	Dialog.addCheckbox("Generate Output Montage", true);
		Dialog.setInsets(0, 40, 0);
  		Dialog.addNumber("ROI Size (pixels square)",200);
  	Dialog.addCheckbox("Generate Montage with Inset", true);
		Dialog.setInsets(0, 40, 0);
		Dialog.addNumber("Inset ROI Size (pixels square)",40);
  		Dialog.setInsets(0, 40, 0);
  		Dialog.addCheckbox("Do DIC with Inset", true);
  	Dialog.addCheckbox("Generate Montages with Filenames", false);
  	Dialog.addCheckbox("Add scalebar", true);
	  	Dialog.setInsets(0, 40, 0);
		Dialog.addNumber("Scalebar size (um)",1);
  	Dialog.addMessage("");
	Dialog.addHelp("http://en.wikipedia.org/wiki/Special:Random");

	Dialog.addChoice("Panel 1",panel_choices,"C1");
	if(number_of_panels>1){
		Dialog.addChoice("Panel 2",panel_choices,"C2");
	}
	if(number_of_panels>2){
		Dialog.addChoice("Panel 3",panel_choices,"C1+C2+C3");
	}
	if(number_of_panels>3){
		Dialog.addChoice("Panel 4",panel_choices,"C4");
	}
	Dialog.show();  	

	EXP_TITLE = Dialog.getString();
  	DO_MONTAGE = Dialog.getCheckbox();
  	MAIN_ROI_SIZE = Dialog.getNumber();
  	DO_INSET = Dialog.getCheckbox();
  	INSET_ROI_SIZE = Dialog.getNumber();
  	DO_DIC_INSET = Dialog.getCheckbox();
  	DO_BURN_FILENAME = Dialog.getCheckbox();
  	DO_SCALEBAR = Dialog.getCheckbox();
  	SCALEBAR_SIZE = Dialog.getNumber();

	PANEL1 = Dialog.getChoice();
		if(number_of_panels>1){
		PANEL2 = Dialog.getChoice();
	}
	if(number_of_panels>2){
		PANEL3 = Dialog.getChoice();
	}
	if(number_of_panels>3){
		PANEL4 = Dialog.getChoice();
	}
  }


function write_config(fpath){
	config_fpath = File.getParent(fpath);
	config_fpath = config_fpath + fs + "config.txt";
	cfg = File.open(config_fpath);
	print(cfg, nCHANNELS + " " + nPANELS + " " + EXP_TITLE+" "+DO_MONTAGE+" "+MAIN_ROI_SIZE+" "+DO_INSET+" "+INSET_ROI_SIZE+" "+DO_DIC_INSET+" "+DO_BURN_FILENAME+" "+DO_SCALEBAR+" "+SCALEBAR_SIZE+" "+CLOSE_ALL_AT_END+" "+PANEL1+" "+PANEL2+" "+PANEL3+" "+PANEL4+" "+ C1_STRING + " "+ C2_STRING + " " + C3_STRING + " " + C4_STRING +" ");
	File.close(cfg);
}

function read_config(config_fpath){

	config_options = split(File.openAsString(config_fpath)," ");
	Array.print(config_options);

	nCHANNELS = config_options[0];
	nPANELS = config_options[1];
	EXP_TITLE = config_options[2];
	DO_MONTAGE = config_options[3];
	MAIN_ROI_SIZE = config_options[4];
	DO_INSET = config_options[5];
	INSET_ROI_SIZE = config_options[6];
	DO_DIC_INSET = config_options[7];
	DO_BURN_FILENAME = config_options[8];
	DO_SCALEBAR = config_options[9];
	SCALEBAR_SIZE = config_options[10];
	CLOSE_ALL_AT_END = config_options[11];
	PANEL1 = config_options[12];
	PANEL2 = config_options[13];
	PANEL3 = config_options[14];
	PANEL4 = config_options[15];
	C1_STRING = config_options[16];
	C2_STRING = config_options[17];
	C3_STRING = config_options[18];
	C4_STRING = config_options[19];
	print(C4_STRING);
	print(config_options[19]);

}

function setup_config(fpath){
	Channel_Setup_Menu(nCHANNELS);
	Panel_Setup_Menu(nPANELS,nCHANNELS);
	write_config(fpath);
}

function Get_Channel(channel_colour){
	if(C1_STRING==channel_colour){return 1;}else{
		if(C2_STRING==channel_colour){return 2;}else{
			if(C3_STRING==channel_colour){return 3;}else{
				if(C4_STRING==channel_colour){return 4;}else{
					return -1;
				}
			}
		}
	}
}	

function make_panel(panel_string,imagelabel,Panel_Number){
	channels = split(panel_string,"+");
	selectWindow(imagelabel);
	run("Duplicate...", "title=temp_panel duplicate");
	run("Split Channels");
	if(channels.length==1){
		selectWindow(channels[0]+"-temp_panel");
		resetMinAndMax();
		Apply_LUT(channels[0]);
		run("Duplicate...", "title=Panel_"+Panel_Number);
		run("RGB Color");
		close("C*-temp_panel");
	}
	if(channels.length==2){
		selectWindow(channels[0]+"-temp_panel");
		resetMinAndMax();
		Apply_LUT(channels[0]);
		selectWindow(channels[1]+"-temp_panel");
		resetMinAndMax();
		Apply_LUT(channels[1]);
		run("Merge Channels...", "c1="+channels[0]+"-temp_panel c2="+channels[1]+"-temp_panel create keep");
		run("RGB Color");
		rename("Panel_"+Panel_Number);
		close("C*-temp_panel");
	}
	if(channels.length==3){
		selectWindow(channels[0]+"-temp_panel");
		resetMinAndMax();
		Apply_LUT(channels[0]);
		selectWindow(channels[1]+"-temp_panel");
		resetMinAndMax();
		Apply_LUT(channels[1]);
		selectWindow(channels[2]+"-temp_panel");
		resetMinAndMax();
		Apply_LUT(channels[2]);
		run("Merge Channels...", "c1="+channels[0]+"-temp_panel c2="+channels[1]+"-temp_panel c3="+channels[2]+"-temp_panel create keep");
		run("RGB Color");
		rename("Panel_"+Panel_Number);
		close("C*-temp_panel");
	}
	if(channels.length==4){
		selectWindow(channels[0]+"-temp_panel");
		resetMinAndMax();
		Apply_LUT(channels[0]);
		selectWindow(channels[1]+"-temp_panel");
		resetMinAndMax();
		Apply_LUT(channels[1]);
		selectWindow(channels[2]+"-temp_panel");
		resetMinAndMax();
		Apply_LUT(channels[2]);
		selectWindow(channels[3]+"-temp_panel");
		resetMinAndMax();
		Apply_LUT(channels[3]);
		run("Merge Channels...", "c1="+channels[0]+"-temp_panel c2="+channels[1]+"-temp_panel c3="+channels[2]+" c4="+channels[3]+"-temp_panel create keep");
		run("RGB Color");
		rename("Panel_"+Panel_Number);
		close("C*-temp_panel");
	}
	close("temp_panel");
}

function Apply_LUT(channel_string){
	if(channel_string == "C1"){run(C1_STRING);}
	if(channel_string == "C2"){run(C2_STRING);}
	if(channel_string == "C3"){run(C3_STRING);}
	if(channel_string == "C4"){run(C4_STRING);}
}
		
function combine_panels_and_montage(){
	if(nPANELS==2){
	run("Concatenate...", "  title=[Concatenated Stacks] keep image1=Panel_1 image2=Panel_2");}	
	if(nPANELS==3){
	run("Concatenate...", "  title=[Concatenated Stacks] keep image1=Panel_1 image2=Panel_2 image3=Panel_3");}
	if(nPANELS==4){
	run("Concatenate...", "  title=[Concatenated Stacks] keep image1=Panel_1 image2=Panel_2 image3=Panel_3 image4=Panel_4");}
	run("Make Montage...", "columns="+nPANELS+" rows=1 scale=1 first=1 last="+nPANELS+" increment=1 border=6 font=12");	
	close("Concatenated Stacks");
}
