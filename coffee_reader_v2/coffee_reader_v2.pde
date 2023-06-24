import processing.video.*;
import java.io.*;
import processing.opengl.*;
Capture cam;
int j=0;
int w=640;
int h=640;
int patch_size=30;
int time=millis()+1000;
boolean played=false;
int mode=0;
int threshold=230;
int match_ind=0;
boolean make_launched=false;
PImage singleImage;
Movie morph;
Movie opener;
Movie eye;
Movie waiter;
Movie closer;
boolean vid_loaded=false;
boolean opener_vid_loaded=false;
boolean image_taken=false;
boolean closer_loaded=false;
int image_time=millis()+10000;
int time_waiter=millis()+10000;
int time_closer=millis()+10000;
int img_h=640; // must change also in python
int img_w=640; // must change also in python
int img_disp_h = 800;
int img_disp_w = 800;
int cam_w=1280;
int cam_h=720;
int tint_alpha=200;
int t_closer=0;
int l;
float brighty=0;

PImage pim = createImage(img_w, img_h, RGB);
PImage pim_f = createImage(720, 720, RGB);

PImage pim_o = createImage(width, height, RGB);
PGraphics pg;
PImage mask=createImage(1920, 1080, RGB);
String[] imageNames = { "house.jpg", "camera.jpg", "heart.jpg", "lookingglass.jpg", "bubble.jpg", "bell.jpg", "envelope.jpg", "eye.jpg", "lock.jpg", "arrow.jpg", "trash.jpg", "sandclock.jpg", "hand.jpg" };
String[] closerNames = { "house.mp4", "camera.mp4", "heart.mp4", "lookingglass.mp4", "bubble.mp4", "bell.mp4", "envelope.mp4", "eye.mp4", "lock.mp4", "arrow.mp4", "trash.mp4", "sandclock.mp4", "hand.mp4" };
PImage[] images = new PImage[imageNames.length];
Movie[] closers = new Movie[closerNames.length];
float w1=(7./16.);
float w2=3./16.;
float w3=(5./16.);
float w4=1./16.;
int newpixel=0;
float quant_error=0;
boolean dither=false;

String fn = "initial_frame.jpg";

//todo:
//1. make camera frame tighter V
//2. make camera frame larger V
//3. add loader V
//4. add closer V
//5 code animation to move last frame of morph above and make smaller. V
//6. remove prints? add all closers. get output from runcommand and use it to choose.
// make sure shape/size of morph movie is ok. perhaps go back to 640 pixels in all. 
// resize files used by the python script once and for all. 
//slow down last frames of morph in python? repeat last frame at least 40ms if not 2 sec. 
void setup() {
  size(1920, 1080, P2D);
  fullScreen(P2D);
  background(0);

  println(width);
  println(height);
  pg = createGraphics(1920, 1080, P2D);

  //size(1200, 1200);
  frameRate(30);
  String[] cameras = Capture.list();
  //Capture.list() ;
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }

    // The camera can be initialized directly using an
    // element from the array returned by list():
    //cam = new Capture(this, 640,480,cameras[1]);
    cam = new Capture(this, cam_w, cam_h, cameras[0]);
    cam.start();
  }

  opener = new Movie(this, "/home/ro/Documents/elad_designweek/coffee_reader_v2/data/cup_loop400.mp4");
  eye = new Movie(this, "/home/ro/Documents/elad_designweek/coffee_reader_v2/data/eye_loop_1920.mp4");
  waiter=new Movie(this, "/home/ro/Documents/elad_designweek/coffee_reader_v2/data/loader_loop_1920a.mp4");
  //closer=new Movie(this, "/home/ro/Documents/elad_designweek/coffee_reader_v2/data/sagir_house.mp4");
  for (int i=0;i<closers.length;i++){
  closers[i]=new Movie(this, closerNames[i]);
  }
  mask=loadImage("/home/ro/Documents/elad_designweek/coffee_reader_v2/data/mask_new.jpg");

  l=pim.width/2+pim.width*pim.height/2;
  println(cam.available());
  //pim.mask(mask);
  for (int i=0; i < imageNames.length; i++) {
    String imageName = imageNames[i];
    images[i] = loadImage(imageName);
    println(images[i].width);
  }
}


void draw() {
  if (mode<30) {
    if (cam.available() == true) {
      cam.read();
    }
  }


  if (mode==0) { // look for cup

    if (opener_vid_loaded==false) {
      println("s0");
      //opener.jump(0);
      opener.play();
      opener_vid_loaded=true;
    }

    pg.beginDraw();

    pg.image(cam, width/2-cam_w/2, height/2-cam_h/2);
    pim = pg.get( width/2-img_w/2, height/2-img_h/2, img_w, img_h);
    //pim.loadPixels();
    pg.image(opener, width/2-200, height/2-200);
    pim_o=pg.get(width/2-200, height/2-200, 400, 400);
    pg.endDraw();

    background(0);
    tint(255, tint_alpha);
    //image(pim, width/2-img_w/2, height/2-img_h/2);//width/2-w/2, height/2-h/2);
    image(pim, width/2-img_disp_w/2, height/2-img_disp_h/2, img_disp_w, img_disp_h);//width/2-w/2, height/2-h/2);
    blendMode(DARKEST);
    tint(255, tint_alpha);

    image(mask, 0, 0);

    //tint(255, tint_alpha);

    image(pim_o, width/2-200, height/2-200);
    blendMode(REPLACE);
    //blend(pim_o, width/2-img_w/2, height/2-img_h/2, img_w, img_h, width/2-img_w/2, height/2-img_h/2, img_w, img_h, DARKEST);
    //blend(pim_o, 0, 0,400,400, width/2-img_w/2, height/2-img_h/2, img_w, img_h, DARKEST);



    brighty=0;
    for (int i = l-patch_size; i < l+patch_size; i++) {
      for (int j=-patch_size; j<patch_size; j++) {

        brighty=brighty+brightness(pim.pixels[i+j*pim.width]);
      }
    }
    //println(brighty);
    if (brighty<threshold*(patch_size*2)*(patch_size*2)) {
      //println("dark");
      if (millis()-time >1800) {
        //present image, start show
        if (played==false) {
          println("showtime");
          mode=1;
          played=true;
          opener.pause();
          opener.jump(0);
        }
      }
    } else {
      //println("no cup");
      played=false;
      time=millis();
      if (opener.time() >= opener.duration()-0.04) {
        opener.jump(0);
      }
    }//bright}
  }

  if (mode==1) { //take picture,  find similarity

    if (image_taken==false) {
      image_time=millis();
      eye.play();

      takeimg();
      println("s1");
    } else {


      pg.beginDraw();
      pg.image(cam, width/2-cam_w/2, height/2-cam_h/2);
      pim = pg.get( width/2-img_w/2, height/2-img_h/2, img_w, img_h);
      pg.image(eye, 0, 0);
      pim_o=pg.get();
      pg.endDraw();
      background(0);
      //tint(255, tint_alpha);

      //image(pim, width/2-img_w/2, height/2-img_h/2);//width/2-w/2, height/2-h/2);
      image(pim, width/2-img_disp_w/2, height/2-img_disp_h/2, img_disp_w, img_disp_h);//width/2-w/2, height/2-h/2);

      blendMode(DARKEST);
      tint(255, tint_alpha);
      image(mask, 0, 0);
      //tint(255, tint_alpha);

      image(pim_o, 0, 0);
      blendMode(REPLACE);

      //blend(pim_o, width/2-img_w/2, height/2-img_h/2, img_w, img_h, width/2-img_w/2, height/2-img_h/2, img_w, img_h, DARKEST);
    }
    if (eye.time() >= eye.duration()-0.04) { //todo sort video so that continuation is after movie is done
      println("s2");
      mode=2;
      eye.pause();
      eye.jump(0);
    }
  }
  if (mode==2) { //present loader,  prepare movie

    if (make_launched==false) {
      waiter.play();
      time_waiter=millis();
      //runcommand(1,false);
      make_launched=true;
    }
    pg.beginDraw();
    pg.image(cam, width/2-cam_w/2, height/2-cam_h/2);
    pim = pg.get( width/2-img_w/2, height/2-img_h/2, img_w, img_h);
    pg.endDraw();
    //background(0);


    //image(pim, width/2-img_w/2, height/2-img_h/2);//width/2-w/2, height/2-h/2);
    image(pim, width/2-img_disp_w/2, height/2-img_disp_h/2, img_disp_w, img_disp_h);//width/2-w/2, height/2-h/2);

    blendMode(DARKEST);
    tint(255, tint_alpha);
    image(mask, 0, 0);
    blendMode(LIGHTEST);
    image(waiter, 0, 0);
    blendMode(REPLACE);

    if (millis()-time_waiter>7000) {
      mode=3;
      waiter.pause();
      waiter.jump(0);
      println("s3");
    }
  }
  if (mode==3) {
    if (vid_loaded!=true) {
      morph = new Movie(this, "morph.mp4");
      morph.play();
      time=millis();
      vid_loaded=true;
    }
    //image(morph, width/2-w/2, height/2-h/2);
    image(morph, width/2-img_disp_w/2, height/2-img_disp_h/2, img_disp_w, img_disp_h);//width/2-w/2, height/2-h/2);
    blendMode(DARKEST);
    tint(255, tint_alpha);
    image(mask, 0, 0);
    blendMode(REPLACE);
    if (morph.time() >= morph.duration()-0.04) { // todo: change to less (0.02?)
      mode=4;
      pim_f=images[match_ind];
      background(0);
      image(pim_f, width/2-img_disp_w/2+(0*2), height/2-img_disp_h/2-0, img_disp_w-(0*4), img_disp_h-(0*4));
      
      morph.stop();
      morph.dispose();

    }
  }

  if (mode==4) {

    if (closer_loaded==false) {
      println("s4");
      closer_loaded=true;
      
      time_closer=millis();
      t_closer=0;
      closers[match_ind].play();
    }

    if (millis()-time_closer<2700) {

      background(0);
      image(pim_f, width/2-img_disp_w/2+(t_closer*2), height/2-img_disp_h/2-t_closer, img_disp_w-(t_closer*4), img_disp_h-(t_closer*4));
      t_closer++;
    } else
    {
      image(closers[match_ind], 0, 0);
      image(pim_f, width/2-img_disp_w/2+(t_closer*2), height/2-img_disp_h/2-t_closer, img_disp_w-(t_closer*4), img_disp_h-(t_closer*4));
    }

    if (millis()-time_closer>12000) {
      mode=0;
      closers[match_ind].pause();
      closers[match_ind].jump(0);

      make_launched=false;


      vid_loaded=false;
      opener_vid_loaded=false;
      image_taken=false;
      closer_loaded=false;
      time=millis()+1000;
      println("finished");
    }
  }

  if (dither==true) {
   loadPixels();


   //for (int i=0; i<pixels.length ; i++){
   //if (i%5==0){pixels[i]=0;}
   //}
  
  for (int y=0; y<height-1; y++){
    for (int x=0; x<width-1; x++){
      int idx=y*width+x;
      float r = red(pixels[idx]);
      float g = green(pixels[idx]);
      float b = blue(pixels[idx]);
      float oldpixel = (r+g+b)/3.;
      if (oldpixel<128) {newpixel=0;} else {newpixel=255;}
      pixels[y*width+x]=color(newpixel);
      quant_error = oldpixel - newpixel;
      //setPixel(x+1,y, pixels[y*width+x+1] + w1 * quant_error);
      //setPixel(x-1,y+1, pixels[(y+1)*width+x-1] + w2 * quant_error);
      //setPixel(x,y+1, pixels[(y+1)*width+x] + w3 * quant_error);
      //setPixel(x+1,y+1, pixels[(y+1)*width+(x+1)] + w4 * quant_error);

      //int c =0;
      //c=pixels[y*width+x+1] + w1 * quant_error;
      pixels[y*width+x+1]= pixels[y*width+x+1] + int(w1 * quant_error);
      pixels[(y+1)*width+x-1]= pixels[(y+1)*width+x-1] + int(w2 * quant_error);
      pixels[(y+1)*width+x]= pixels[(y+1)*width+x] + int(w3 * quant_error);
      pixels[(y+1)*width+x+1]= pixels[(y+1)*width+(x+1)] + int(w4 * quant_error);
      
    }
  }
  
   updatePixels();
  }
  filter(GRAY);
}

void takeimg() {

  image_taken=true;
  pg.beginDraw();
  pg.image(cam, width/2-cam_w/2, height/2-cam_h/2);
  pim = pg.get( width/2-img_w/2, height/2-img_h/2, img_w, img_h);
  pg.endDraw();


  pim.save(fn);
  match_ind=runcommand(0, true);
}


void movieEvent(Movie m) {
  if (m==eye) {
    eye.read();
  }
  if (m==morph) {
    morph.read();
  }
  if (m==closer) {
    closer.read();
  }
  if (m==opener) {
    opener.read();
  }
  if (m==waiter) {
    waiter.read();
  }
  for (int i=0;i<closerNames.length;i++){
  if (m==closers[i]){
  closers[i].read();}
  }
}


int runcommand (int a, boolean wait) {
  File workingDir = new File("/home/ro/Documents/elad_designweek/coffee_reader/");   // where to do it - should be full path
  // what command to run
  String commandToRun ="";
  if (a==0) {
    commandToRun = "python3 /home/ro/Documents/code/RIFE-interpolation/image_sim.py";
  } else {
    workingDir=new File("/home/ro/Documents/code/RIFE-interpolation/");
    commandToRun = " python3 inference_img.py --img /home/ro/Documents/elad_designweek/coffee_reader/initial_frame.jpg /home/ro/Documents/elad_designweek/first_last/img-0129.png --exp=8 --match_ind "+str(match_ind);
  }
  // String commandToRun = "ls";
  // String commandToRun = "wc -w sourcefile.extension";
  // String commandToRun = "cp sourcefile.extension destinationfile.extension";
  // String commandToRun = "./yourBashScript.sh";


  String returnedValues;    // value to return any results
  int realout=-1;

  // give us some info:
  println("Running command: " + commandToRun);
  println("Location:        " + workingDir);
  println("---------------------------------------------\n");

  // run the command!
  try {

    // complicated!  basically, we have to load the exec command within Java's Runtime
    // exec asks for 1. command to run, 2. null which essentially tells Processing to
    // inherit the environment settings from the current setup (I am a bit confused on
    // this so it seems best to leave it), and 3. location to work (full path is best)
    Process p = Runtime.getRuntime().exec(commandToRun, null, workingDir);
    if (wait==false) {
      return 0;
    }
    //if (a!=0){
    //return 0;}
    // variable to check if we've received confirmation of the command
    int i = p.waitFor();

    // if we have an output, print to screen
    if (i == 0) {
      println("run cmd ok");
      // BufferedReader used to get values back from the command
      BufferedReader stdInput = new BufferedReader(new InputStreamReader(p.getInputStream()));

      // read the output from the command
      while ( (returnedValues = stdInput.readLine ()) != null) {
        //int a=3;
        //println(returnedValues);
        realout =int(returnedValues);
        //return int(returnedValues);
      }
    }

    // if there are any error messages but we can still get an output, they print here
    else {
      println("run cmd  err");

      BufferedReader stdErr = new BufferedReader(new InputStreamReader(p.getErrorStream()));

      // if something is returned (ie: not null) print the result
      while ( (returnedValues = stdErr.readLine ()) != null) {

        println(returnedValues);
      }
    }
  }

  // if there is an error, let us know
  catch (Exception e) {
    println("Error running command!");
    println(e);
  }

  return realout;
}
