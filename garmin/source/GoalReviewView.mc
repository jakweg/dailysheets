import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application;


class GoalReviewInitialView extends WatchUi.View {
    hidden var mDay;

    function initialize(day) {
        View.initialize();
        mDay = day;
    }

    public function onLayout( dc ) as Void {
        setLayout( Rez.Layouts.GoalReviewInitialLayout( dc ) );

        (findDrawableById("TitleLabel") as Text).setText(mDay);
    }
}

class GoalReviewFinalView extends WatchUi.View {
    function initialize() {
        View.initialize();
    }

    public function onLayout( dc ) as Void {
        setLayout( Rez.Layouts.GoalReviewInitialLayout( dc ) );

        (findDrawableById("TitleLabel") as Text).setText("All done! Ready to sync");
    }
}

class FinalViewDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onSelect() {
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        var delegate = new FullSyncDelegate();
        WatchUi.pushView(
            delegate.getView(),
            delegate,
            WatchUi.SLIDE_LEFT
        );
        delegate.start();
        return true;
    }
}

class GoalReviewDelegate extends WatchUi.BehaviorDelegate {
    hidden var mView;
    hidden var mDay;
    hidden var mGoalIndex;
    hidden var mGoalsSize;
    hidden var mOnReviewSelected;
    hidden var mReviewGiven;
    function initialize(view, onReviewSelected, day, goalIndex, goalsSize) {
        BehaviorDelegate.initialize();
        mView = view.weak();
        mOnReviewSelected = onReviewSelected;
        mDay = day;
        mGoalIndex = goalIndex;
        mGoalsSize = goalsSize;
        mReviewGiven = false;
    }

    function onReviewGiven(value) {
        if (mReviewGiven) { return; }
        mReviewGiven = true;
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

        mView.get().onReviewGiven(value);
        mOnReviewSelected.invoke(mView.get().isKeysMode);
    }

    function onSelectScore_0() {
        onReviewGiven(0);
    }
    function onSelectScore_1() {
        onReviewGiven(1);
    }
    function onSelectScore_2() {
        onReviewGiven(2);
    }
    function onSelectScore_3() {
        onReviewGiven(3);
    }
    function onSelectScore_4() {
        onReviewGiven(4);
    }
    function onSelectScore_5() {
        onReviewGiven(5);
    }

    function onSelect() {
        if (mView.get().isKeysMode)
            { return false; }
        mView.get().onSelect();
        return true;
    }

    function onBack() {
        if (!mView.get().isKeysMode)
            { return false; }
        mView.get().onBack();
        return true;
    }

    function onSelectable(event as WatchUi.SelectableEvent) as Lang.Boolean {
        if (event.getInstance().getState() == :stateSelected) {
            var value = (event.getInstance().identifier as String).toNumber();
            onReviewGiven(value);
        } 
        return true;
    }
}

class GoalReviewView extends WatchUi.View {
    public var isKeysMode = false;
    hidden var mGoalTitle;
    hidden var mGoalCategory;
    hidden var mGoalIndex;
    hidden var mTotalGoals;

    function initialize(goalTitle, goalCategory, goalIndex, totalGoals, isKeysMode_) {
        View.initialize();
        isKeysMode = isKeysMode_;
        mGoalTitle = goalTitle;
        mGoalCategory = goalCategory;
        mGoalIndex = goalIndex;
        mTotalGoals = totalGoals;
    }

    public function onLayout( dc ) as Void {
        var drawables = Rez.Layouts.GoalReviewLayout( dc );
        setLayout(drawables);

        var buttonId = 0;
        for( var i = 0; i < drawables.size(); i++ ) {
            var drawable = drawables[i];
            if (drawable instanceof WatchUi.Button) {
                buttonId++;
                drawable.identifier = "" + buttonId;
            }
        }

        (findDrawableById("TitleLabel") as Text).setText(mGoalTitle);
        (findDrawableById("NumerLabel") as Text).setText("" + (mGoalIndex + 1) + "/" + mTotalGoals);
        (findDrawableById("GoalCategory") as Text).setText(mGoalCategory);
    }

    public function onSelect() {
        isKeysMode = true;
        setKeyToSelectableInteraction(true);
    }
    public function onBack() {
        isKeysMode = false;
        setKeyToSelectableInteraction(false);
    }

    public function onReviewGiven(value) {
        for (var i = 0; i <= 5;i++) {
            if (i != value) {
                (findDrawableById("emoji" + i) as Text).setVisible(false);
            }
        }
    }

    public function onShow() {
        setKeyToSelectableInteraction(isKeysMode);
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
    hidden var mIsKeysMode;

    public var loop;

    function initialize(day, goalsArray, categoriesArray) {
        ViewLoopFactory.initialize();
        mDay = day;
        mGoalsArray = goalsArray;
        mCategoriesArray = categoriesArray;
        mIsKeysMode = false;
    }


    function getSize() as Lang.Number {
        return mGoalsArray.size() + 2;
    }

    function getView(page as Lang.Number) as [ WatchUi.View ] or [ WatchUi.View, WatchUi.BehaviorDelegate ] {
        var size = mGoalsArray.size();
        if (page == 0) {
            var dialog = new GoalReviewInitialView(mDay);
            return [dialog, new WatchUi.BehaviorDelegate()];
        }
        page--;

        if (page == size) {
            var dialog = new GoalReviewFinalView();
            return [dialog, new FinalViewDelegate()];
        }

        var goalTitle = mGoalsArray[page][1];
        var goalCategory = mCategoriesArray[mGoalsArray[page][0]];

        var view = new GoalReviewView(goalTitle, goalCategory, page, size, mIsKeysMode);
        var delegate = new GoalReviewDelegate(view, method(:moveToNextPage), mDay, page, size);
        return [view, delegate];
    }

    function timerCallback() as Void     {

        var aliveLoop = loop.get();
        if (aliveLoop != null) {
            try {
                aliveLoop.changeView(WatchUi.ViewLoop.DIRECTION_NEXT);
            } catch(e) {
                // ignore
            }
        }
    }

    function moveToNextPage(isKeysMode) {
        mIsKeysMode = isKeysMode;
        var myTimer = new Timer.Timer();
        myTimer.start(method(:timerCallback), 500, false);
    }

}

class MyViewLoopDelegate extends WatchUi.ViewLoopDelegate {
    hidden var mLoop;
    function initialize(loop) {
        ViewLoopDelegate.initialize(loop);
        mLoop = loop;
    }

    function onNextView() {
        return mLoop.changeView( WatchUi.ViewLoop.DIRECTION_NEXT );
    }
    function onPreviousView() {
        return mLoop.changeView( WatchUi.ViewLoop.DIRECTION_PREVIOUS );
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