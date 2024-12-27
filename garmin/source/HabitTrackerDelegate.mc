import Toybox.Lang;
import Toybox.WatchUi;

class HabitTrackerDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onMenu() as Boolean {
        WatchUi.pushView(new Rez.Menus.MainMenu(), new HabitTrackerMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

}