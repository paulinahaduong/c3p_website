ArrayList<Level> levels;
ArrayList<Textbox> textboxes;
Level currentLevel;
int currentLevelIndex;
boolean[] keys;
CollisionManager collisionManager;
Physics physics;
PImage flagTexture;
PImage playerTexture;

void setup() {
  size(480, 360);
  collisionManager = new CollisionManager();
  physics = new Physics(new Vector2(0, .02f));
  textboxes = new ArrayList<Textbox>();
  
  //Levels
  currentLevelIndex = 0;
  levels = new ArrayList<Level>();
  levels.add(new Level0());
  levels.add(new Level1());
  levels.add(new Level2());
  levels.add(new Level3());
  levels.add(new Level4());
  currentLevel = levels.get(currentLevelIndex);

  keys = new boolean[4];
  keys[0] = false;
  keys[1] = false;
  keys[2] = false;
  keys[3] = false;
  
  //Load textures
  flagTexture = loadImage("assets/games/csDiversityGame/data/flag.png");
  playerTexture = loadImage("assets/games/csDiversityGame/data/player.png");
}

void draw() {
  background(255);
  textSize(15);

  physics.update(currentLevel.gameobjects);
  collisionManager.testCollisions(currentLevel.gameobjects);
  
  ArrayList<GameObject> tmp = new ArrayList<GameObject>(currentLevel.gameobjects);
 for(int i = 0; i < tmp.size(); i++) {
   tmp.get(i).updateObject();
   tmp.get(i).drawObject();
 }
 
 for(int i = 0; i < textboxes.size(); i++) {
   textboxes.get(i).display();
 }
}

void clearText() {
 textboxes.clear(); 
}

void displayText(String text, AABB bounds) {
  textboxes.add(new Textbox(text, bounds));
}

void displayText(Textbox text) {
 textboxes.add(text);
}
void changeLevel() {
  if(currentLevelIndex >= levels.size() - 1) {
    currentLevel.gameobjects.clear();
  } else {
    currentLevel = levels.get(++currentLevelIndex); 
  }
}

void keyPressed()
{
  if(keyCode==UP)
    keys[0]=true;
  if(keyCode==DOWN)
    keys[1]=true;
  if(keyCode==LEFT)
    keys[2]=true;
  if(keyCode==RIGHT)
    keys[3]=true;
}

void keyReleased()
{
  if(keyCode==UP)
    keys[0]=false;
  if(keyCode==DOWN)
    keys[1]=false;
  if(keyCode==LEFT)
    keys[2]=false;
  if(keyCode==RIGHT)
    keys[3]=false;
}

class AABB {
  int minX;
  int minY;
  int maxX;
  int maxY;
  
  public AABB(int minX, int minY, int maxX, int maxY) {
   this.minX = minX;
   this.minY = minY;
   this.maxX = maxX;
   this.maxY = maxY;
  }
  
  public boolean intersects(AABB other) {
    return (maxX >= other.minX && other.maxX >= minX) &&
           (maxY >= other.minY && other.maxY >= minY);
  }
  
  public Vector2 distanceTo(AABB other) {
    int dX = distance1D(minX, other.minX, maxX, other.maxX);
    int dY = distance1D(minY, other.minY, maxY, other.maxY);
    
    return Math.abs(dX) < Math.abs(dY) ? new Vector2(dX,0) : new Vector2(0,dY);
  }
  
  public int distance1D(int min1, int min2, int max1, int max2) {
    if(max1 < max2) {
     return max1 - min2;
    } else {
     return min1 - max2; 
    }
  }
}
class CollisionManager {
  public void testCollisions(ArrayList<GameObject> gameobjects) {
    for(int i = 0; i < gameobjects.size(); i++) {
      GameObject go1 = gameobjects.get(i);
      go1.onGround = false;
      for(int j = i+1; j < gameobjects.size(); j++) {
        GameObject go2 = gameobjects.get(j);
        
        if(go1.canBeMoved) {
          if(collide(go1, go2)) {
            if(go2.isGround && go1.getBounds().maxY <= go2.getBounds().minY) {
             go1.onGround = true;
             go1.acceleration.y = 0;
             go1.velocity.y = 0;
            }
            
           go1.collisionEvent(go2, gameobjects); 
           go2.collisionEvent(go1, gameobjects); 
          }
        }
      }
    }
  }
  
  public boolean collide(GameObject a, GameObject b) {
    AABB aBounds = a.getBounds();
    AABB bBounds = b.getBounds();
    
    if(aBounds.intersects(bBounds)) {
      Vector2 mtv = aBounds.distanceTo(bBounds);
      a.move(new Vector2(-mtv.x, -mtv.y));
      b.move(mtv);
    
      return true;
    }
    
    return false;
  }
}
class Flag extends GameObject {
  private Textbox text;
  int delay;
  int currentTime;
  boolean removeObject;
  
  public Flag(Textbox text, Vector2 pos, Vector2 size) {
   super(pos, size, false, false);
   this.text = text;
   currentTime = 0;
   delay = 33;
  }
  
  public void updateObject() {
    if(removeObject) {
      if(currentTime++ > delay) {
       changeLevel();
     }
    }
  }
  
  public void drawObject() {
   image(flagTexture, pos.x, pos.y, size.x, size.y); 
  }
  
  public void collisionEvent(GameObject other, ArrayList<GameObject> gameobjects) {
   if(other instanceof Player) {
     clearText();
     displayText(text);
     
     //Remove object
     pos.y = 1000;
     removeObject = true;
   }
  }
}
abstract class GameObject {
  //Physics
 public Vector2 pos;
 public Vector2 velocity;
 public Vector2 acceleration;
 public float friction;
 public boolean canBeMoved;
 public boolean onGround;
 public Vector2 size;
 public boolean isGround;

 public abstract void updateObject();
 public void collisionEvent(GameObject other, ArrayList<GameObject> gameobjects) {}
 
 public GameObject(Vector2 pos, Vector2 size, boolean canBeMoved, boolean isGround) {
   this.pos= pos;
   this.size = size;
   this.canBeMoved = canBeMoved;
   friction = .95;
   onGround = false;
   this.isGround = isGround;
   
   velocity = new Vector2(0, 0);
   acceleration = new Vector2(0, 0);
 }
 
 public AABB getBounds() {
   return new AABB(Math.round(pos.x), Math.round(pos.y), Math.round(size.x+pos.x), Math.round(size.y+pos.y));
 }
 
  public void drawObject() {
   AABB bounds = getBounds();
   rect(bounds.minX, bounds.minY, bounds.maxX - pos.x, bounds.maxY - pos.y);
   
   move(velocity);
 }
 
 public void move(Vector2 moveVector) {
   if(canBeMoved) {
    pos.Add(moveVector); 
   }
 }
 
 public void addForce(Vector2 force) {
   acceleration.x += force.x;
   acceleration.y += force.y;
 }
}
class Level {
 ArrayList<GameObject> gameobjects;
 
 public Level() {
  gameobjects = new ArrayList<GameObject>();
 }  
}
class Level0 extends Level {
 public Level0() {
  gameobjects.add(new Player(2, new Vector2(15, 0), new Vector2(15, 0), new Vector2(16, 16)));
  gameobjects.add(new Wall(new Vector2(450, 290), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(400, 300), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(350, 190), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(300, 230), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(250, 130), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(200, 140), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(150, 100), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(100, 120), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(50, 150), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(0, 160), new Vector2(50, 400)));
  gameobjects.add(new Flag(new Textbox("", new AABB(0, 0, 10, 10)), new Vector2(417, 268), new Vector2(16, 32)));
  
  textboxes.add(new Textbox("Computer Game", new AABB(width/2 - 100, 20, 200, 100)));
  textboxes.add(new Textbox("Start", new AABB(405, 300, 50, 100)));
 }
}
class Level1 extends Level {
 public Level1() {
  gameobjects.add(new Player(2, new Vector2(15, 0), new Vector2(15, 0), new Vector2(16, 16)));
  gameobjects.add(new Wall(new Vector2(0, 100), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(100, 100), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(200, 70), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(300, 170), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(400, 300), new Vector2(50, 400)));
  gameobjects.add(new Wall(new Vector2(400, 0), new Vector2(50, 225)));
  gameobjects.add(new Flag(new Textbox("I complained to everyone I could think of; got no support." +
  "Then I was laid off since they were culling the workforce and I was a 'low performer.'" +
  "My prior project has praised and awarded me, so I assure you it wasn't skill.", new AABB(180, 10, 280, 500)), new Vector2(417, 268), new Vector2(16, 32)));
 }
}
class Level2 extends Level {
 public Level2() {
  gameobjects.add(new Player(2, new Vector2(120, 280), new Vector2(120, 280), new Vector2(16, 16)));
  gameobjects.add(new Wall(new Vector2(100, 300), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(10, 240), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(100, 180), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(10, 120), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(100, 60), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(340, 300), new Vector2(60, 10)));
  gameobjects.add(new Flag(new Textbox("When I was nominated for prom queen, I got comments like 'well THAT makes sense, but why she's pretending to be a programmer?'",
    new AABB(85, 265, 270, 100)), new Vector2(362, 268), new Vector2(16, 32)));
 }
}

class Level3 extends Level {
 public Level3() {
  gameobjects.add(new Player(2, new Vector2(30, 280), new Vector2(30, 280), new Vector2(16, 16)));
  gameobjects.add(new Wall(new Vector2(10, 300), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(120, 240), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(10, 180), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(10, 120), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(120, 60), new Vector2(60, 60)));
  gameobjects.add(new Wall(new Vector2(220, 60), new Vector2(60, 60)));
  gameobjects.add(new Wall(new Vector2(310, 200), new Vector2(120, 5)));
  gameobjects.add(new Wall(new Vector2(340, 300), new Vector2(60, 5)));
  
  gameobjects.add(new Flag(new Textbox("Many of my classmates at HGSE are treated as inferior because of their race and/or gender by professors, " +
  "classmates, committees, etc. relative to their white male peers. One professor used the n-word in class, for example.", new AABB(width / 2 - 150, height / 2 - 150, 300, 300)), new Vector2(362, 268), new Vector2(16, 32)));
 }
}

class Level4 extends Level {
 public Level4() {
  gameobjects.add(new Player(2, new Vector2(30, 280), new Vector2(30, 280), new Vector2(16, 16)));
  gameobjects.add(new Wall(new Vector2(10, 300), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(110, 300), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(210, 300), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(310, 300), new Vector2(60, 10)));
  gameobjects.add(new Wall(new Vector2(412, 300), new Vector2(60, 10)));

  
  gameobjects.add(new Flag(new Textbox("You Win!!!", new AABB(width / 2 - 150, height / 2 - 150, 300, 300)), new Vector2(434, 268), new Vector2(16, 32)));
 }
}

class Physics {
 Vector2 gravity;
 
 public Physics(Vector2 gravity) {
  this.gravity = gravity; 
 }
 
 public void update(ArrayList<GameObject> gameobjects) {
   for(int i = 0; i < gameobjects.size(); i++) {
     GameObject go = gameobjects.get(i);
     go.addForce(gravity);
     go.velocity.x *= go.friction;
     go.velocity.y *= go.friction;
     go.acceleration.x *= go.friction;
     go.acceleration.y *= go.friction;
     
     go.velocity.x += go.acceleration.x;
     go.velocity.y += go.acceleration.y;
   }
 }
}

class Player extends GameObject {
  int speed;
  Vector2 spawn;
  
  public Player(int speed, Vector2 spawn, Vector2 pos, Vector2 size) {
   super(pos, size, true, false);
   this.speed = speed; 
   this.spawn = spawn;
  }
  
  public void drawObject() {
   image(playerTexture, pos.x, pos.y, size.x, size.y); 
   move(velocity);
  }
  
  public void updateObject() {
     if(keys[0] && onGround) {
       velocity.y -= 8;
     }
     
     if(keys[1]) {
       pos.y += speed;
     }
     
     if(keys[2]) {
       pos.x -= speed;
     }
     
     if(keys[3]) {
       pos.x += speed;
     }
     
     //Respawing
     if(pos.y > 360) {
      pos.x = spawn.x;
      pos.y = spawn.y;
     }
  }
}

class Textbox {
 public String text;
 private AABB bounds;
 
 public Textbox(String text, AABB bounds) {
   this.text = text;
   this.bounds = bounds;
 }
 
 public void display() {
   fill(0);
   text(text, bounds.minX, bounds.minY, bounds.maxX, bounds.maxY);
   fill(255);
 }
}class Vector2 {
 float x;
 float y;
 
 public Vector2(float x, float y) {
  this.x = x;
  this.y = y;
 }
 
 public void Add(Vector2 toAdd) {
   x += toAdd.x;
   y += toAdd.y;
 }
}

class Wall extends GameObject {
  public Wall(Vector2 pos, Vector2 size) {
   super(pos, size, false, true);
  }


  public void updateObject() {
    
  }
}
