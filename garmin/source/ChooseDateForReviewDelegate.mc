import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ChooseDateForReviewDelegate extends WatchUi.Menu2InputDelegate {

    hidden var mView;
    function initialize() {
        Menu2InputDelegate.initialize();

        var datesObject = Application.Storage.getValue("dates") as Dictionary<String, String>;

        mView = new WatchUi.Menu2({
            :title => "Choose day",
            :focus => datesObject["suggestedToday"] as Number
        });

        var datesList = datesObject["dates"] as Array<String>;
        for( var i = 0; i < datesList.size(); i++ ) {
            mView.addItem(
                new WatchUi.MenuItem(
                    datesList[i],
                    null,
                    datesList[i],
                    {}
                )
            );
        }
    }

    function getView() {
        return mView;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        openGoalReview(item.getId() as String, null, null);
    }

}