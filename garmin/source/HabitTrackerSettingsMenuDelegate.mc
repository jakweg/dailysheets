import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class HabitTrackerSettingsMenuDelegate extends WatchUi.MenuInputDelegate {

    hidden var mStorage as ReviewStorage;
    function initialize(storage) {
        MenuInputDelegate.initialize();
        mStorage = storage;
    }

    function onMenuItem(item as Symbol) as Void {
        if (item == :sync) {
            var delegate = new FullSyncDelegate(mStorage);
            WatchUi.pushView(
                delegate.getView(),
                delegate,
                WatchUi.SLIDE_LEFT
            );
            delegate.start();
        } else if (item == :review) {
            var delegate = new ChooseDateForReviewDelegate(mStorage);
            WatchUi.pushView(
                delegate.getView(),
                delegate,
                WatchUi.SLIDE_LEFT
            );
        }
    }

}