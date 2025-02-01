import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class FullSyncDelegate extends WatchUi.InputDelegate {

    hidden var mStorage as ReviewStorage;
    hidden var mView;

    hidden var mDatesToSet;

    function initialize(storage) {
        InputDelegate.initialize();
        mStorage = storage;
        mView = new WatchUi.ProgressBar(
            loadResource(Rez.Strings.Syncing),
            null
        );
        mDatesToSet = null;
    }

    function getView() {
        return mView;
    }
    function onBack() {
        return true;
    }

    function start() {
        var reviewsGivenObject = mStorage.getRawPendingReviewsObject();
        if (reviewsGivenObject == null) {
            reviewsGivenObject = {};
        }

        var goals = mStorage.getGoalsArray();
        if (goals == null) {
            goals = [];
        }

        new MultidayReviewPusher(method(:mOnCurrentReviewsPushed), reviewsGivenObject, goals).start();
    }

    function mOnCurrentReviewsPushed(ok, data) as Void {
        if (!ok) {
            WatchUi.showToast(Rez.Strings.SyncFailed, {:icon=>Rez.Drawables.warningToastIcon});
            WatchUi.popView(WatchUi.SLIDE_BLINK);
            return;
        }

        new ApiCall(method(:mOnDaysLoaded)).getDays();
    }

    function mOnDaysLoaded(ok, data) as Void {
        if (!ok) {
            WatchUi.showToast(Rez.Strings.SyncFailed, {:icon=>Rez.Drawables.warningToastIcon});
            WatchUi.popView(WatchUi.SLIDE_BLINK);
            return;
        }

        mDatesToSet = data;

        new ApiCall(method(:mOnGoalsLoaded)).getGoals();
    }

    function mOnGoalsLoaded(ok, data) as Void {
        if (!ok) {
            WatchUi.showToast(Rez.Strings.SyncFailed, {:icon=>Rez.Drawables.warningToastIcon});
            WatchUi.popView(WatchUi.SLIDE_BLINK);
            return;
        }

        mStorage.commitSyncDone(mDatesToSet, data);
        mStorage.saveToDeviceMemory();

        WatchUi.showToast(Rez.Strings.SyncOk, {:icon=>Rez.Drawables.positiveToastIcon});
        WatchUi.popView(WatchUi.SLIDE_BLINK);
    }
}