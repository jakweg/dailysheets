import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class HabitTrackerSettingsMenuDelegate extends WatchUi.MenuInputDelegate {

    function initialize() {
        MenuInputDelegate.initialize();
    }

    function onMenuItem(item as Symbol) as Void {
        openGoalReview("2025-01-22", null, null);
        // if (item == :sync) {
        //     var delegate = new FullSyncDelegate();
        //     WatchUi.pushView(
        //         delegate.getView(),
        //         delegate,
        //         WatchUi.SLIDE_LEFT
        //     );
        //     delegate.start();
        // } else if (item == :review) {
        //     var delegate = new ChooseDateForReviewDelegate();
        //     WatchUi.pushView(
        //         delegate.getView(),
        //         delegate,
        //         WatchUi.SLIDE_LEFT
        //     );
        // }
    }

}