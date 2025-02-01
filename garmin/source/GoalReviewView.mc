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
    hidden var mStorage as ReviewStorage;
    function initialize(storage) {
        BehaviorDelegate.initialize();
        mStorage = storage;
    }

    function onSelect() {
        WatchUi.popView(WatchUi.SLIDE_LEFT);
        var delegate = new FullSyncDelegate(mStorage);
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

        mView.get().onReviewGiven(value);
        mOnReviewSelected.invoke(value, mGoalIndex, mView.get().isKeysMode);
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

    function onKey(keyEvent) {
        if (keyEvent.getKey() != WatchUi.KEY_ENTER) {
            return false;
        }
        if (mView.get().isKeysMode) {
            return false;
        }
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
    hidden var mCurrentReview;
    hidden var mTotalGoals;

    function initialize(goalTitle, goalCategory, goalIndex, totalGoals, currentReview, isKeysMode_) {
        View.initialize();
        isKeysMode = isKeysMode_;
        mGoalTitle = goalTitle;
        mGoalCategory = goalCategory;
        mGoalIndex = goalIndex;
        mCurrentReview = currentReview;
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
        if (mCurrentReview != -1) {
            var emojis = [
                "🤐",
                "🤮",
                "😞",
                "😐",
                "🙂",
                "🥳"
            ];
            (findDrawableById("CurrentReview") as Text).setText(emojis[mCurrentReview]);
        }
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
    hidden var mStorage as ReviewStorage;
    hidden var mDay;
    hidden var mIsKeysMode;

    public var loop;

    function initialize(day, storage) {
        ViewLoopFactory.initialize();
        mStorage = storage;
        mDay = day;
        mIsKeysMode = false;
    }


    function getSize() as Lang.Number {
        return mStorage.getGoalsArray().size() + 2;
    }

    function getView(page as Lang.Number) as [ WatchUi.View ] or [ WatchUi.View, WatchUi.BehaviorDelegate ] {
        if (page == 0) {
            var dialog = new GoalReviewInitialView(mDay);
            return [dialog, new WatchUi.BehaviorDelegate()];
        }
        page--;

        var goals = mStorage.getGoalsArray();
        var size = goals.size();

        if (page == size) {
            var dialog = new GoalReviewFinalView();
            return [dialog, new FinalViewDelegate(mStorage)];
        }

        var goalTitle = goals[page][1];
        var goalCategory = mStorage.getCategoryByIndex(goals[page][0]);

        var currentReview = mStorage.getReviewValue(mDay, page);

        var view = new GoalReviewView(goalTitle, goalCategory, page, size, currentReview, mIsKeysMode);
        var delegate = new GoalReviewDelegate(view, method(:onReviewGiven), mDay, page, size);
        return [view, delegate];
    }

    function timerCallback() as Void     {

        var aliveLoop = loop.get();
        if (aliveLoop != null) {
            aliveLoop.changeView(WatchUi.ViewLoop.DIRECTION_NEXT);
        }
    }

    function onReviewGiven(value, goalIndex, isKeysMode) {

        mStorage.giveReview(mDay, goalIndex, value);

        mIsKeysMode = isKeysMode;
        var myTimer = new Timer.Timer();
        myTimer.start(method(:timerCallback), 300, false);
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

function openGoalReview(day as String, storage as ReviewStorage) {
    var factory = new MyViewLoopFactory(day, storage);
    var loop = new WatchUi.ViewLoop(factory, { :wrap => false });
    factory.loop = loop.weak();
    WatchUi.pushView(loop, new MyViewLoopDelegate(loop), 
        WatchUi.SLIDE_LEFT);
}