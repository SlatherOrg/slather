require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Slather::ProfdataCoverageFile do

  let(:fixtures_project) do
    Slather::Project.open(FIXTURES_PROJECT_PATH)
  end

  let(:profdata_coverage_file) do
    Slather::ProfdataCoverageFile.new(fixtures_project, "/Users/venmo/ExampleProject/AppDelegate.swift:
       |    1|//
       |    2|//  AppDelegate.swift
       |    3|//  xcode7workbench01
       |    4|//
       |    5|//  Created by Simone Civetta on 08/06/15.
       |    6|//  Copyright © 2015 Xebia IT Architects. All rights reserved.
       |    7|//
       |    8|
       |    9|import UIKit
       |   10|
       |   11|@UIApplicationMain
       |   12|class AppDelegate: UIResponder, UIApplicationDelegate {
       |   13|
       |   14|    var window: UIWindow?
       |   15|
       |   16|
      1|   17|    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
      1|   18|        // Override point for customization after application launch.
      1|   19|        return true
      1|   20|    }
       |   21|
      0|   22|    func applicationWillResignActive(application: UIApplication) {
      0|   23|        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
      0|   24|        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
      0|   25|    }
       |   26|
      0|   27|    func applicationDidEnterBackground(application: UIApplication) {
      0|   28|        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
      0|   29|        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
      0|   30|    }
       |   31|
      0|   32|    func applicationWillEnterForeground(application: UIApplication) {
      0|   33|        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
      0|   34|    }
       |   35|
      1|   36|    func applicationDidBecomeActive(application: UIApplication) {
      0|   37|        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
      0|   38|    }
       |   39|
      0|   40|    func applicationWillTerminate(application: UIApplication) {
      0|   41|    }
       |   42|
       |   43|
       |   44|}
       |   45|")
  end

  describe "#initialize" do
    it "should create a list of lines" do
      expect(profdata_coverage_file.line_data.length).to eq(45)
      expect(profdata_coverage_file.line_data[9]).to eq("       |    9|import UIKit")
    end
  end

  describe "#all_lines" do
    it "should return a list of all the lines" do
      expect(profdata_coverage_file.all_lines.length).to eq(45)
      expect(profdata_coverage_file.all_lines[8]).to eq("       |    9|import UIKit")
    end
  end

  describe "#line_number_in_line" do
    it "should return the correct line number" do
      expect(profdata_coverage_file.line_number_in_line("      0|   40|    func applicationWillTerminate(application: UIApplication) {")).to eq(40)
    end
  end

  describe "#coverage_for_line" do
    it "should return the number of hits for the line" do
      expect(profdata_coverage_file.coverage_for_line("      10|   40|    func applicationWillTerminate(application: UIApplication) {")).to eq(10)
    end

    it "should return the number of hits for a line in thousands as an integer" do
      result = profdata_coverage_file.coverage_for_line("  11.8k|   49|    return result;")
      expect(result).to eq(11800)
      expect(result).to be_a(Fixnum)
    end

    it "should return the number of hits for a line in millions as an integer" do
      result = profdata_coverage_file.coverage_for_line("  2.58M|   49|    return result;")
      expect(result).to eq(2580000)
      expect(result).to be_a(Fixnum)
    end

    it "should return the number of hits for an uncovered line" do
      expect(profdata_coverage_file.coverage_for_line("      0|   49|    return result;")).to eq(0)
    end
  end

  describe "#num_lines_tested" do
    it "should count the actual number of line tested" do
      expect(profdata_coverage_file.num_lines_tested).to eq(5)
    end
  end

  describe "#num_lines_testable" do
    it "should count the actual testable number of line" do
      expect(profdata_coverage_file.num_lines_testable).to eq(20)
    end
  end

  describe "#percentage_line_tested" do
    it "should count the percentage of tested lines" do
      expect(profdata_coverage_file.percentage_lines_tested).to eq(25)
    end
  end

  describe "#ignored" do

    before(:each) {
      allow(fixtures_project).to receive(:ignore_list).and_return([])
    }

    it "shouldn't ignore project files" do
      ignorable_file = Slather::ProfdataCoverageFile.new(fixtures_project, "/Users/venmo/ExampleProject/AppDelegate.swift:
       |    1|//
       |    2|//  AppDelegate.swift
       |    3|//  xcode7workbench01")

      expect(ignorable_file.ignored?).to be_falsy
    end

    it "should ignore platform files" do
      ignorable_file = Slather::ProfdataCoverageFile.new(fixtures_project, "../../../../../../../../Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks/XCTest.framework/Headers/XCTestAssertionsImpl.h:
       |    1|//
       |    2|//  AppDelegate.swift
       |    3|//  xcode7workbench01")

      expect(ignorable_file.ignored?).to be_truthy
    end

  end

end