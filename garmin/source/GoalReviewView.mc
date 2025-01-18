import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application;



class GoalActionMenuDelegate extends WatchUi.ActionMenuDelegate {
    hidden var mOnReviewSelected;
    function initialize(onReviewSelected) {
        ActionMenuDelegate.initialize();
        mOnReviewSelected = onReviewSelected;
    }

    function onBack() as Void {
    }

    function onSelect(item as WatchUi.ActionMenuItem) as Void {
        var value = (item.getId() as String).toNumber();

        mOnReviewSelected.invoke(value);
    }
}

class GoalReviewDelegate extends WatchUi.BehaviorDelegate {
    hidden var mDay;
    hidden var mGoalIndex;
    hidden var mGoalsSize;
    hidden var mOnReviewSelected;
    function initialize(onReviewSelected, day, goalIndex, goalsSize) {
        BehaviorDelegate.initialize();
        mOnReviewSelected = onReviewSelected;
        mDay = day;
        mGoalIndex = goalIndex;
        mGoalsSize = goalsSize;
    }
    function onTap(clickEvent) {
        System.println(clickEvent.getCoordinates()); // e.g. [36, 40]
        System.println(clickEvent.getType());        // CLICK_TYPE_TAP = 0
        return true;
    }

    function onReviewGiven(value) {
        var reviewsGivenObject = (Application.Storage.getValue("reviews-given") as Dictionary<String, Array<Number>>);
        if (reviewsGivenObject == null) {
            reviewsGivenObject = {};
        }

        var forThisDay = reviewsGivenObject[mDay];
        if (forThisDay == null) {
            forThisDay = new [mGoalsSize];
            for (var i = 0;i < mGoalsSize; i++) {
                forThisDay[i] = -1;
            }
            reviewsGivenObject[mDay] = forThisDay;
        }

        forThisDay[mGoalIndex] = value;

        Application.Storage.setValue("reviews-given", reviewsGivenObject);

        mOnReviewSelected.invoke();
    }

    function onSelectScore_0() {
        System.println("onTouch0");
    }
    function onSelectScore_1() {
        System.println("onTouch1");
    }
    function onSelectScore_2() {
        System.println("onTouch2");
    }
    function onSelectScore_3() {
        System.println("onTouch3");
    }
    function onSelectScore_4() {
        System.println("onTouch4");
    }
    function onSelectScore_5() {
        System.println("onTouch5");
    }

    // function onSelect() {
    //     var menu = new WatchUi.ActionMenu(null);
    //     menu.addItem(new WatchUi.ActionMenuItem({ :label => "Nie dotyczy" }, "0"));
    //     menu.addItem(new WatchUi.ActionMenuItem({ :label => "Wspaniale" }, "5"));
    //     menu.addItem(new WatchUi.ActionMenuItem({ :label => "Dobrze" }, "4"));
    //     menu.addItem(new WatchUi.ActionMenuItem({ :label => "Przeciętnie" }, "3"));
    //     menu.addItem(new WatchUi.ActionMenuItem({ :label => "Słabo" }, "2"));
    //     menu.addItem(new WatchUi.ActionMenuItem({ :label => "Porażka" }, "1"));

    //     WatchUi.showActionMenu(menu,
    //         new GoalActionMenuDelegate(method(:onReviewGiven))
    //     );

    //     return true;
    // }
    function onSelectable(event as WatchUi.SelectableEvent) as Lang.Boolean {
    System.println("Instance " + event.getInstance());
    System.println("PrevState " + event.getPreviousState());
    System.println("GetState " + event.getInstance().getState());
    return true;
    }
}

class GoalReviewView extends WatchUi.View {
    hidden var mGoalTitle;
    hidden var mGoalCategory;
    hidden var mGoalIndex;
    hidden var mTotalGoals;
    function onSelectable(event) {
    System.println("Instance " + event.getInstance());
    System.println("PrevState " + event.getPreviousState());
    System.println("GetState " + event.getInstance().getState());
    return true;
    }

    function initialize(goalTitle, goalCategory, goalIndex, totalGoals) {
        View.initialize();
        mGoalTitle = goalTitle;
        mGoalCategory = goalCategory;
        mGoalIndex = goalIndex;
        mTotalGoals = totalGoals;
    }

    public function onLayout( dc ) as Void {
        setLayout( Rez.Layouts.GoalReviewLayout( dc ) );
        setKeyToSelectableInteraction(true);

        (findDrawableById("TitleLabel") as Text).setText(mGoalTitle);
        (findDrawableById("NumerLabel") as Text).setText("" + (mGoalIndex + 1) + "/" + mTotalGoals);
        (findDrawableById("GoalCategory") as Text).setText(mGoalCategory);
        System.println("Hello world");
    }

    public function onUpdate( dc ) as Void {
        View.onUpdate( dc );
    }

    function onHide() {
    }
}

class MyViewLoopFactory extends WatchUi.ViewLoopFactory {
    hidden var mDay;
    hidden var mGoalsArray;
    hidden var mCategoriesArray;

    public var loop;

    function initialize(day, goalsArray, categoriesArray) {
        ViewLoopFactory.initialize();
        mDay = day;
        mGoalsArray = goalsArray;
        mCategoriesArray = categoriesArray;
    }


    function getSize() as Lang.Number {
        return mGoalsArray.size();
    }

    function getView(page as Lang.Number) as [ WatchUi.View ] or [ WatchUi.View, WatchUi.BehaviorDelegate ] {
        var goalTitle = mGoalsArray[page][1];
        var goalCategory = mCategoriesArray[mGoalsArray[page][0]];

        var view = new GoalReviewView(goalTitle, goalCategory, page, mGoalsArray.size());
        var delegate = new GoalReviewDelegate(method(:moveToNextPage), mDay, page, mGoalsArray.size());
        return [view, delegate];
    }

    function moveToNextPage() {
        var aliveLoop = loop.get();
        if (aliveLoop != null) {
            aliveLoop.changeView(WatchUi.ViewLoop.DIRECTION_NEXT);
        }
    }

}

class MyViewLoopDelegate extends WatchUi.ViewLoopDelegate {
    function initialize(loop) {
        ViewLoopDelegate.initialize(loop);
    }

    // function onNextView() as Lang.Boolean {
    //     return true;
    // }

    function onSelectable(event as WatchUi.SelectableEvent) as Lang.Boolean {
    System.println("Instance " + event.getInstance());
    System.println("PrevState " + event.getPreviousState());
    System.println("GetState " + event.getInstance().getState());
    return true;
    }
}

function openGoalReview(day as String, goalsArray, categoriesArray) {
    if (goalsArray == null) {
        var tmp = (Application.Storage.getValue("goals") as Dictionary<String, String>);
        if (tmp == null) {
            var delegate = new FullSyncDelegate();
            WatchUi.pushView(
                delegate.getView(),
                delegate,
                WatchUi.SLIDE_LEFT
            );
            delegate.start();
            return;
        }

        goalsArray = tmp["goals"];
        categoriesArray = tmp["categories"];
    }
    var factory = new MyViewLoopFactory(day, goalsArray, categoriesArray);
    var loop = new WatchUi.ViewLoop(factory, { :wrap => false });
    factory.loop = loop.weak();
    WatchUi.pushView(loop, new MyViewLoopDelegate(loop), 
        WatchUi.SLIDE_LEFT);
}