import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ChooseDateForReviewDelegate extends WatchUi.Menu2InputDelegate {

    hidden var mStorage as ReviewStorage;
    hidden var mView;
    function initialize(storage) {
        Menu2InputDelegate.initialize();
        mStorage = storage;

        mView = new WatchUi.Menu2({
            :title => Rez.Strings.ChooseDay,
            :focus => mStorage.getSuggestedDateIndex()
        });

        var datesList = mStorage.getReviewAvailableDaysList();
        for( var i = 0; i < datesList.size(); i++ ) {
            var value = datesList[i];
            mView.addItem(
                new WatchUi.MenuItem(
                    value,
                    null,
                    value,
                    {}
                )
            );
        }
    }

    function getView() {
        return mView;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        openGoalReview(item.getId() as String, mStorage);
    }

}