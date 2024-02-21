import Toybox.Application;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Math;
import Toybox.Position;
import Toybox.Weather;

var bitmapHour;
var bitmapMin;
var bitmapSec;
var width;
var height;
var weekdays = ["", "niedziela", "poniedziałek", "wtorek", "środa", "czwartek", "piątek", "sobota"] as Array<String>;

var bluetoothIcon = "続"; // 32154
var notificationIcon = "知"; // 30693
var sunriseIcon = "太"; // 22826
var sunsetIcon = "陽"; // 38525
var stepsIcon = "歩"; // 27497
var dotFilledIcon = "満"; // 28288
var dotEmptyIcon = "空"; // 31354


class WatchFaceView extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        bitmapHour = WatchUi.loadResource(Rez.Drawables.bitmapHour);
        bitmapMin = WatchUi.loadResource(Rez.Drawables.bitmapMin);
        bitmapSec = WatchUi.loadResource(Rez.Drawables.bitmapSec);
        width = dc.getWidth();
        height = dc.getHeight();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        var clockTime = System.getClockTime();
        var hour = clockTime.hour;
        var min = clockTime.min;
        var sec = clockTime.sec;

        if (!System.getDeviceSettings().is24Hour && hour > 12) {
            hour = hour - 12;
        }

        var hourBigString = hour.format("%02d");
        var minBigString = min.format("%02d");
        var timeString = Lang.format("$1$:$2$", [hourBigString, minBigString]);


        // UPDATE THE VIEWS
        var notifView = View.findDrawableById("notif") as Text;
        notifView.setText(getNotifText());

        var bigTimeView = View.findDrawableById("bigTime") as Text;
        bigTimeView.setText(timeString);
        
        var dayView = View.findDrawableById("day") as Text;
        dayView.setText(getDayText());
        
        var textAreaView = View.findDrawableById("textarea") as Text;
        textAreaView.setText(getSunData() + "\n" + getStepsLine());


        // Call the parent onUpdate function to redraw the layout
        // this has to be done AFTER view updates and BEFORE dc drawing
        View.onUpdate(dc);

        // CALCULATING CLOCK HAND ANGLES
        // seconds
        var secAngle = sec * 6.0;
        var minAngle = min*6.0 + secAngle/60;
        var hourAngle = (hour % 12)*30 + minAngle/12;
        
        var hourTransform = new Graphics.AffineTransform();
        rotateHand(hourTransform, hourAngle);
        dc.drawBitmap2((width/2), (height/2), bitmapHour, { :transform => hourTransform });
        
        var minTransform = new Graphics.AffineTransform();
        rotateHand(minTransform, minAngle);
        dc.drawBitmap2((width/2), (height/2), bitmapMin, { :transform => minTransform });
        
        var secTransform = new Graphics.AffineTransform();
        rotateHand(secTransform, secAngle);
        dc.drawBitmap2((width/2), (height/2), bitmapSec, { :transform => secTransform });
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

    protected function rotateHand(tform as Graphics.AffineTransform, angle as Float) as Void {
        // I designed hands to be at 135 degrees
        var rad = Math.toRadians(angle - 135);
        tform.rotate(rad);
    }

    protected function getNotifText() as String {
        var str = "";
        var devSet = System.getDeviceSettings();
        if (devSet.phoneConnected) {
            str += bluetoothIcon + " ";
        }
        if (devSet.notificationCount != null) {
            str += notificationIcon + " ";
            if (devSet.notificationCount >= 20) {
                str += "20+";
            } else {
                str += devSet.notificationCount.toString();
            }
        }
        return str;
    }

    protected function getDayText() as String {
        var info = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var weekday = (weekdays as Array<String>)[info.day_of_week];
        var dayFormatted = info.day.format("%02d");
        var monthFormatted = info.month.format("%02d");
        var dateStr = weekday + ", " + dayFormatted + "." + monthFormatted;
        return dateStr;
    }

    protected function getSunData() as String {
        var str = "";
        var currCond = Weather.getCurrentConditions();
        var position;
        position = new Position.Location({:latitude => 52.232222, :longitude => 21.008333, :format => :degrees});
        if (currCond != null && currCond.observationLocationPosition != null) {
            position = currCond.observationLocationPosition;
        }
        var sunrise = Weather.getSunrise(position, Time.now());
        var sunset = Weather.getSunset(position, Time.now());
        var sunriseStr = "...";
        var sunsetStr = "...";

        if (sunrise != null) {
            var sunriseT = Time.Gregorian.info(sunrise, Time.FORMAT_SHORT);
            sunriseStr = sunriseT.hour.format("%02d");
            sunriseStr += ":";
            sunriseStr += sunriseT.min.format("%02d");
        }

        if (sunset != null) {
            var sunsetT = Time.Gregorian.info(sunset, Time.FORMAT_SHORT);
            sunsetStr = sunsetT.hour.format("%02d");
            sunsetStr += ":";
            sunsetStr += sunsetT.min.format("%02d");
        }
        
        str += sunriseIcon + " " + sunriseStr;
        str += "  ";
        str += sunsetIcon + " " + sunsetStr;
        return str;
    }

    protected function getStepsLine() as String {
        var steps = ActivityMonitor.getInfo().steps;
        var goal = ActivityMonitor.getInfo().stepGoal;
        var percent = Math.round(100.0 * steps / goal).toNumber();
        var numberOfDots = 5;
        var filledDots = Math.floor((percent % 100) / (100 / numberOfDots));
        if (percent > 100) { filledDots = numberOfDots; }
        var emptyDots = numberOfDots - filledDots;

        var dots = "";
        for (var i = 0; i < filledDots; i++) { dots += dotFilledIcon; }
        for (var i = 0; i < emptyDots; i++)  { dots += dotEmptyIcon; }

        var str = "";
        str += stepsIcon;
        str += " ";
        str += steps.toString();
        str += "   ";
        str += dots;
        return str;
    }
}
