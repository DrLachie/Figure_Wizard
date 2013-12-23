/*
 * NEW IMPROVED DR_Figure_Wizard
 * 
 * 	Added menus, still a work in progress.
 * 	A little way to go yet
 * 	 
 * 	
 * 
 */

//Global variables, set by menu or use these as defaults

var EXP_TITLE = "filename";
var DO_MONTAGE = true;
var MAIN_ROI_SIZE = 200;
var DO_INSET = false;
var INSET_ROI_SIZE = 40;
var DO_DIC_INSET = false;
var DO_BURN_FILENAME = false;
var DO_SCALEBAR = true;
var SCALEBAR_SIZE = 1;
var CLOSE_ALL_AT_END = false;

var fs = File.separator();
var BLUE_CHANNEL = 3;
var GREEN_CHANNEL = 1;
var RED_CHANNEL = 2;
var DIC_CHANNEL = 4;


if(nImages==0){
	file_path = File.openDialog("Select File to Process");
	run("Bio-Formats Importer", "open=["+file_path+"] autoscale color_mode=Default view=Hyperstack stack_order=XYCZT");
}
	/* 
	 *  Lots of improvements to be made
	 *  
	 *  
	 *  
	 */
		
		fname = getInfo("image.filename");

		a=custom_menu();
		
		//Show middle slice, (change to find middle slice)
		getDimensions(WIDTH, HEIGHT, CHANNELS, SLICES, FRAMES);
		
		//PUT ERROR CHECKING IN HERE (channel numbers, frames, slices);
		
		Stack.setPosition(DIC_CHANNEL, SLICES/2, 1);
		
		//Add ROI size to menu
		makeRectangle(WIDTH/2 - MAIN_ROI_SIZE/2, HEIGHT/2 - MAIN_ROI_SIZE/2, MAIN_ROI_SIZE, MAIN_ROI_SIZE);
		waitForUser("Main ROI", "Move the ROI to wherever you want it") ;
		
		run("Duplicate...", "title="+fname+"roi duplicate");//channels=1-4 slices=1-30");
		close(fname);
		
		
		//Select single slice for slice view
		Stack.setPosition(GREEN_CHANNEL, SLICES/2, 1);
		waitForUser("Select Plane", "Select \"Best\" Plane") ;
		
		Stack.getPosition(channel,BEST_SLICE,time); 
		run("Duplicate...", "title="+fname+"roi2 duplicate channels=1-4 slices="+BEST_SLICE);
		//close(fname+"roi");
		
		Stack.setPosition(GREEN_CHANNEL,1,1); 
		
		//ROTATION - Dave wants this 
		
		/* 
		 *  //waitForUser("Rotate?", "Rotate if required, or just press ok");
		//Call angle tool;
		//waitForUSER("Rotate?", "measure angle of rotation required");
		//get angle
		//rotate image by angle calculated
		
		//waitForUser("Flip?",...) if yes then flip horizontally.
		 */
		
		imname = fname+"roi2";
		//Do first without inset whether or not dic_inset was selected;
		Make_Montage(imname,false,DO_DIC_INSET,DO_SCALEBAR,DO_BURN_FILENAME);
		
		if(DO_INSET){
			Make_Montage(imname,DO_INSET,DO_DIC_INSET,DO_SCALEBAR,DO_BURN_FILENAME);
		}
		
		
		
		//CLEAN UP
			close(fname+"roi");
			close(fname+"roi2");
			if(isOpen("Roi Manager")){selectWindow("ROI Manager");run("Close");}
			
			if(CLOSE_ALL_AT_END){
				run("Close All");
		
		
		



/*
 * HERE BE FUNCTIONS
 * Improvements still to come
 * "to be self-contented is to be vile and ignorant, and that to aspire is better than to be blindly and impotently happy."
 * 
 */


function Make_Montage(window_label,add_inset,do_DIC_inset,add_scalebar,add_filename){
	selectWindow(window_label);
	run("Duplicate...", "title=to_montage duplicate channels=1-4");
	to_montage = "to_montage";//bit of a hack, sorry
	run("Split Channels");
	selectWindow("C1-"+to_montage);
	resetMinAndMax();
	selectWindow("C2-"+to_montage);
	resetMinAndMax();
	selectWindow("C3-"+to_montage);
	resetMinAndMax();
	selectWindow("C4-"+to_montage);
	resetMinAndMax();
	run("Merge Channels...", "c1=C"+RED_CHANNEL+"-"+to_montage+" c2=C"+GREEN_CHANNEL+"-"+to_montage+" c3=C"+BLUE_CHANNEL+"-"+to_montage+" create keep");
	run("RGB Color");
	rename("Panel_3");
	//rename("Composite (RGB)"); //Another small hack
	close("Composite");
	close("C3-"+to_montage);
	
	selectWindow("C"+GREEN_CHANNEL+"-"+to_montage);
	run("Green");
	run("RGB Color");
	rename("Panel_2");
	selectWindow("C"+RED_CHANNEL+"-"+to_montage);
	run("Red");
	run("RGB Color");
	rename("Panel_1");
	selectWindow("C"+DIC_CHANNEL+"-"+to_montage);
	rename("Panel_4");
	//Put scale bar option in menu

	if(add_scalebar){
		run("Scale Bar...", "width=1 height=4 font=14 color=White background=None location=[Lower Right] hide");
	}
	
	run("RGB Color");
	
	//Make stack for montage
	run("Concatenate...", "  title=[Concatenated Stacks] keep image1=Panel_1 image2=Panel_2 image3=Panel_3 image4=Panel_4 image5=[-- None --]");
	
	//Montage and save
	if(!add_inset){	
		run("Make Montage...", "columns=4 rows=1 scale=1 first=1 last=4 increment=1 border=6 font=12");	
		rename("First Montage");
		
			
			if(DO_BURN_FILENAME){
				run("Duplicate...", "title=[FIRST MONTAGE-with filename]");
				print("Doin stuiff");
				setForegroundColor(200,200,200); //Adjust Caption color
				setFont("SansSerif", 18, "bold"); //adjust to change appearance of caption ("bold" can be removed and "SansSerif" can be changed to "Serif");
				xpos=10;ypos=35; //adjust these to move the caption around
				caption=EXP_TITLE;
				drawString(caption,xpos,ypos);
			}
		
		
		//saveAs("Tif",outpath+fname+"_montage");
		close("Panel_1");
		close("Panel_2");
		close("Panel_3");
		close("Panel_4");
		close("Concatenated Stacks");
		//close("Composite (RGB)");
	}else{
		//add these to advanced options (color and width of border
		run("Colors...", "foreground=white background=black selection=yellow");
		run("Line Width...", "line=3");
		
			
		selectWindow("Concatenated Stacks");
		
		//Add size option to menu - error check to make smaller than .5? original
		makeRectangle(MAIN_ROI_SIZE/2 - INSET_ROI_SIZE/2, MAIN_ROI_SIZE/2 - INSET_ROI_SIZE/2, INSET_ROI_SIZE, INSET_ROI_SIZE);
		//setSlice(3);
		
		//Add smaller ROI for invasion things (to menu as well))
		waitForUser("Main ROI", "Move the ROI to wherever you want it") ;
		run("Duplicate...", "title=[zoomed] duplicate range=1-3");
		run("Scale...", "x=2 y=2 width=90 height=90 interpolation=None average process create");
		run("Stack to Images");
		close("zoomed");
		close("Concatenated Stacks");

		//add inset to red channel 
		selectWindow("Panel_1");
		run("Add Image...", "image=zoomed-1-0001 x=112 y=112 opactiy=100");
		run("ROI Manager...");
		roiManager("Show All");
		roiManager("Show None");
		run("Flatten");
		close("Panel_1");
		close("zoomed-1-0001");
		makeRectangle(112,112,81,81);
		run("Draw");
		roiManager("Show All");
		roiManager("Show None");
		rename("Panel_1");

		//add inset to green channel 
		selectWindow("Panel_2");
		run("Add Image...", "image=zoomed-1-0002 x=112 y=112 opactiy=100");
		roiManager("Show All");
		roiManager("Show None");
		run("Flatten");
		close("Panel_2");
		close("zoomed-1-0002");
		makeRectangle(112,112,81,81);
		run("Draw");
		//run("ROI Manager...");
		roiManager("Show All");
		roiManager("Show None");
		rename("Panel_2");

		//add inset to merged channel 
		selectWindow("Panel_3");
		run("Add Image...", "image=zoomed-1-0003 x=112 y=112 opactiy=100");
		roiManager("Show All");
		roiManager("Show None");
		run("Flatten");
		close("Panel_3");
		makeRectangle(112,112,81,81);
		run("Draw");
		run("ROI Manager...");
		roiManager("Show All");
		roiManager("Show None");
		rename("Panel_3");

		//DO DIC INSET IF ASKED FOR
		if(do_DIC_inset){
			selectWindow("Panel_4");
			run("Add Image...", "image=zoomed-1-0003 x=112 y=112 opactiy=100");
			roiManager("Show All");
			roiManager("Show None");
			run("Flatten");
			makeRectangle(112,112,81,81);
			run("Draw");
			run("ROI Manager...");
			roiManager("Show All");
			roiManager("Show None");
			rename("DIC_INSET");
		}

		close("zoomed-1-0003");
	
		//Setup stack for montage
		run("Concatenate...", "  title=[Temp Stack] keep image1=Panel_1 image2=Panel_2 image3=Panel_3 image4=Panel_4 image5=[-- None --]");
		run("Make Montage...", "columns=4 rows=1 scale=1 first=1 last=4 increment=1 border=6 font=12");
		rename("Montage_w_insets");
	
			
			if(DO_BURN_FILENAME){
				run("Duplicate...", "title=[Montage_w_insets-with filename]");
				print("Doin stuiff");
				setForegroundColor(200,200,200); //Adjust Caption color
				setFont("SansSerif", 18, "bold"); //adjust to change appearance of caption ("bold" can be removed and "SansSerif" can be changed to "Serif");
				xpos=10;ypos=35; //adjust these to move the caption around
				caption=EXP_TITLE;
				drawString(caption,xpos,ypos);
			}
		
		
		
		close("Temp Stack");
		close("Panel_1");
		close("Panel_2");
		close("Panel_3");
		close("Panel_4");	
	}

	

	}



}
	

function custom_menu(){
/*	Variables set by first menu
 * 	Experiment title (default to fname)
 * 	Generate Montage (YES/NO - is there any reason to click no?)
 * 		Main ROI Size (default 200)
 * 	Generate Inset Montage (Y/N)
 * 		Inset ROI Size (Default 80)
 * 		Generate DIC with Inset (Y/N)
 * 	Add Filenames to images (Y/N) (as well, or instead?)
 * 	Add Scalebar (Y/N)
 * 		Scalebar Size (default to 1um) 	
 * 		
 */

	fname=getInfo("image.filename");
	

	instructions = "Code by L.Whitehead.\n Whitehead@wehi.edu.au\n	\r\n- Instructions go here";

	menu_title = "DRiglar Figure Wizard";
	Dialog.create(menu_title);
	Dialog.setInsets(0, 20, 0);
  	Dialog.addMessage("About:");
  	Dialog.addMessage(instructions);
  	Dialog.setInsets(0, 20, 0);
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
  	Dialog.addCheckbox("Advanced Options", false);

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
	AdvOpt = Dialog.getCheckbox();

/*   
 * 	Advanced options menu sets
 * 	channel numbers (defaults: G1,R2,B3,DIC4)
 *    	Save defaults to config.txt file? <-Is this possible?
 *    
 *    
 */

	if(AdvOpt){
		Dialog.create("Advanced Options");
		Dialog.addMessage("Adjust as needed");
		Dialog.addChoice("Channel 1:", newArray("Red", "Green", "Blue", "DIC"),"Green");
		Dialog.addChoice("Channel 2:", newArray("Red", "Green", "Blue", "DIC"),"Red");
		Dialog.addChoice("Channel 3:", newArray("Red", "Green", "Blue", "DIC"),"Blue");
		Dialog.addChoice("Channel 4:", newArray("Red", "Green", "Blue", "DIC"),"DIC");
		Dialog.addCheckbox("Save as new defauls", true)

		//min_size = Dialog.getNumber();
		Dialog.show();
	}
		c1=Dialog.getChoice();
		c2=Dialog.getChoice();
		c3=Dialog.getChoice();
		c4=Dialog.getChoice();
		channels_in_numeric_order = newArray(c1,c2,c3,c4);

		for(i=0;i<channels_in_numeric_order.length;i++){
			
			if(matches(channels_in_numeric_order[i],"Red")){
				RED_CHANNEL = i+1;}
			if(matches(channels_in_numeric_order[i],"Green")){
				GREEN_CHANNEL = i+1;}
			if(matches(channels_in_numeric_order[i],"Blue")){
				BLUE_CHANNEL = i+1;}
			if(matches(channels_in_numeric_order[i],"DIC")){
				DIC_CHANNEL = i+1;}
			}
		
	Array.print(channels_in_numeric_order);
	return 14
}

