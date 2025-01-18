import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class FullSyncDelegate extends WatchUi.InputDelegate {

    hidden var mView;
    function initialize() {
        InputDelegate.initialize();
        mView = new WatchUi.ProgressBar(
            "Syncing...",
            null
        );
    }

    function getView() {
        return mView;
    }
    function onBack() {
        return true;
    }

    function start() {
        var reviewsGivenObject = (Application.Storage.getValue("reviews-given") as Dictionary<String, Array<Number>>);
        if (reviewsGivenObject == null) {
            reviewsGivenObject = {};
        }

        var goals = Application.Storage.getValue("goals");
        if (goals == null) {
            goals = [];
        }

        new MultidayReviewPusher(method(:mOnCurrentReviewsPushed), reviewsGivenObject, goals).start();
    }

    function mOnCurrentReviewsPushed(ok, data) as Void {
        if (!ok) {
            WatchUi.showToast("Failed to sync", {:icon=>Rez.Drawables.warningToastIcon});
            WatchUi.popView(WatchUi.SLIDE_BLINK);
            return;
        }

        Application.Storage.deleteValue("reviews-given");

        new ApiCall(method(:mOnDaysLoaded)).getDays();
    }

    function mOnDaysLoaded(ok, data) as Void {
        if (!ok) {
            WatchUi.showToast("Failed to sync", {:icon=>Rez.Drawables.warningToastIcon});
            WatchUi.popView(WatchUi.SLIDE_BLINK);
            return;
        }

        Application.Storage.setValue("dates", data);

        new ApiCall(method(:mOnGoalsLoaded)).getGoals();
    }

    function mOnGoalsLoaded(ok, data) as Void {
        if (!ok) {
            WatchUi.showToast("Failed to sync", {:icon=>Rez.Drawables.warningToastIcon});
            WatchUi.popView(WatchUi.SLIDE_BLINK);
            return;
        }

        Application.Storage.setValue("goals", data);

        WatchUi.showToast("Synced successfully", {:icon=>Rez.Drawables.positiveToastIcon});
        WatchUi.popView(WatchUi.SLIDE_BLINK);
    }
}