import QtQuick 2.12
import QtTest 1.2
import "../../qml" as App
Item {
    width: 850; height: 480
    QtObject { id: audio; property int plays: 0; function playStartupSound() { plays++ } }
    Component { id: introComponent; App.StartupIntro { width:850; height:480; running:true; audioController:audio; movieComponent:Qt.resolvedUrl("MovieStub.qml") } }
    SignalSpy { id: completed; signalName:"finished" }
    TestCase {
        name:"StartupIntro"; when:windowShown
        function init() { audio.plays=0; completed.clear() }
        function makeIntro() {
            var intro=createTemporaryObject(introComponent,parent)
            verify(intro!==null)
            var movie=findChild(intro,"startupMovieLoader")
            tryCompare(movie,"status",Loader.Ready)
            completed.target=intro
            return intro
        }
        function test_sound_starts_on_movie_playback_once() {
            var intro=makeIntro(), movie=findChild(intro,"startupMovieLoader").item
            compare(audio.plays,0)
            movie.playbackStarted()
            compare(audio.plays,1)
            movie.playbackStarted()
            compare(audio.plays,1)
            movie.playbackFinished()
            compare(audio.plays,1)
        }
        function test_hud_prepared_before_movie_finishes() {
            var intro=makeIntro()
            intro.hudReady=true
            compare(completed.count,0)
            findChild(intro,"startupMovieLoader").item.playbackStarted()
            findChild(intro,"startupMovieLoader").item.playbackFinished()
            compare(intro.complete,true)
            compare(completed.count,1)
        }
        function test_final_frame_held_until_hud_ready() {
            var intro=makeIntro()
            findChild(intro,"startupMovieLoader").item.playbackFinished()
            compare(intro.animationDone,true)
            compare(completed.count,0)
            intro.hudReady=true
            compare(completed.count,1)
        }
        function test_decoder_failure_uses_timed_still_and_sound() {
            var intro=makeIntro()
            intro.hudReady=true
            findChild(intro,"startupMovieLoader").item.playbackFailed()
            compare(audio.plays,1)
            var timer=findChild(intro,"startupMovieFallback")
            compare(timer.running,true)
            timer.interval=20
            tryCompare(intro,"complete",true)
            compare(audio.plays,1)
        }
        function test_continue_is_idempotent() {
            var intro=makeIntro()
            intro.hudReady=true
            intro.finishAnimation()
            intro.finishAnimation()
            compare(completed.count,1)
            compare(audio.plays,1)
        }
    }
}
