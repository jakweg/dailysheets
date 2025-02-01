import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Application;

class ReviewStorage {
    // key is date, such as "2025-02-01", value is array of goal review numbers
    hidden var mReviewsPendingObject as Dictionary<String, Array<Number>>;
    // array of pairs [categoryIndex, goalName]
    hidden var mGoalsArray as Array<Array>;
    hidden var mGoalsCategoriesArray as Array<String>;

    hidden var mDatesList as Array<String>;
    hidden var mSuggestedDayIndex as Number;

    // key is date, such as "2025-02-01", value is array of goal review numbers
    hidden var mReviewsPushedObject as Dictionary<String, Array<Number>>;

    function initialize() {
        mReviewsPendingObject = {};
        mGoalsArray = [];
        mGoalsCategoriesArray = [];
        mDatesList = [];
        mSuggestedDayIndex = -1;
        mReviewsPushedObject = {};
    }

    function loadFromDeviceMemory() {
        var pushedReviewsObject = (Application.Storage.getValue("pushed-reviews") as Dictionary<String, Array<Number>>);
        if (pushedReviewsObject == null) {
            pushedReviewsObject = {};
        }
        mReviewsPushedObject = pushedReviewsObject;

        var reviewsPendingObject = (Application.Storage.getValue("pending-reviews") as Dictionary<String, Array<Number>>);
        if (reviewsPendingObject == null) {
            reviewsPendingObject = {};
        }
        mReviewsPendingObject = reviewsPendingObject;


        var goalsObject = (Application.Storage.getValue("goals") as Dictionary<String, String>);
        if (goalsObject == null) {
            goalsObject = { "goals" => [], "categories" => [] };
        }

        mGoalsArray = goalsObject["goals"] as Array<Array>;
        mGoalsCategoriesArray = goalsObject["categories"] as Array<String>;


        var datesObject = Application.Storage.getValue("dates") as Dictionary<String, String>;
        if (datesObject == null) {
            datesObject = {"dates" => [], "suggestedToday" => -1};
        }
        mDatesList = datesObject["dates"] as Array<String>;
        mSuggestedDayIndex = datesObject["suggestedToday"] as Number;
    }

    function saveToDeviceMemory() {
        Application.Storage.setValue("pending-reviews", mReviewsPushedObject);
        Application.Storage.setValue("pending-reviews", mReviewsPendingObject);
        Application.Storage.setValue("goals", {
            "goals" => mGoalsArray,
            "categories" => mGoalsCategoriesArray,
        });
        Application.Storage.setValue("dates", {
            "dates" => mDatesList,
            "suggestedToday" => mSuggestedDayIndex,
        });
    }

    function getSuggestedDateIndex() as Number {
        return mSuggestedDayIndex;
    }
    function getReviewAvailableDaysList() as Array<String> {
        return mDatesList;
    }
    function needsSync() as Boolean {
        return mGoalsArray.size() == 0;
    }
    function getGoalsArray() as Array<Array> {
        return mGoalsArray;
    }
    function giveReview(day as String, goalIndex as Number, reviewValue as Number) as Void {
        var forThisDay = mReviewsPendingObject[day];
        if (forThisDay == null) {
            var goalsSize = getGoalsArray().size();
            forThisDay = new [goalsSize];
            for (var i = 0;i < goalsSize; i++) {
                forThisDay[i] = -1;
            }
            mReviewsPendingObject[day] = forThisDay;
        }

        forThisDay[goalIndex] = reviewValue;
    }
    function getReviewValue(day as String, goalIndex as Number) as Number {
        var forThisDay = mReviewsPendingObject[day];
        if (forThisDay == null) {
            forThisDay = mReviewsPushedObject[day];
            if (forThisDay == null) {
                return -1;
            }
        }

        return forThisDay[goalIndex];
    }
    function getRawPendingReviewsObject() {
        return mReviewsPendingObject;
    }
    function getCategoryByIndex(index) {
        return mGoalsCategoriesArray[index];
    }
    function commitSyncDone(rawDatesObject, rawGoalsObject) {

        mDatesList = rawDatesObject["dates"] as Array<String>;
        mSuggestedDayIndex = rawDatesObject["suggestedToday"] as Number;

        var newGoalsArray = rawGoalsObject["goals"];
        // if goals are new then clear pushed goals array as well
        var shouldClear = false;
        if (newGoalsArray.size() != mGoalsArray.size()) {
            shouldClear = true;
        } else {
            for (var i = 0; i < mGoalsArray.size(); ++i) {
                if (!newGoalsArray[i][1].equals(mGoalsArray[i][1])) {
                    shouldClear = true;
                    break;
                }
            }
        }
        if (shouldClear) {
            mReviewsPushedObject = {};
        } else {
            var daysThatGotPushed = mReviewsPendingObject.keys();
            for (var i = 0; i < daysThatGotPushed.size(); ++i) {
                var day = daysThatGotPushed[i];
                var reviewsArray = mReviewsPendingObject[day];
                if (!mReviewsPushedObject.hasKey(day)) {
                    mReviewsPushedObject[day] = reviewsArray;
                } else {
                    for (var j = 0;j < reviewsArray.size(); ++j) {
                        if (reviewsArray[j] != -1) {
                            mReviewsPushedObject[day][j] = reviewsArray[j];
                        }
                    }
                }
            }
        }

        mGoalsArray = newGoalsArray;
        mGoalsCategoriesArray = rawGoalsObject["categories"];

        mReviewsPendingObject = {};
    }
}