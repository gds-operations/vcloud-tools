require 'spec_helper'

describe Vcloud::Query do
  context "attributes" do

    context "our object should have methods" do
      before(:each) do
        @mock_fog_interface = StubFogInterface.new
        Vcloud::FogServiceInterface.stub(:new).and_return(@mock_fog_interface)
        @query = Vcloud::Query.new()
      end
      it { @query.should respond_to(:run) }
    end

    context "#run with no type set" do
      
      before(:each) do
        @mock_fog_interface = StubFogInterface.new
        Vcloud::FogServiceInterface.stub(:new).and_return(@mock_fog_interface)
        @query = @query = Vcloud::Query.new()
      end

      it "should call output_potential_query_types when run not provided with a type" do
        @query.should_receive(:output_potential_query_types)
        @query.run()
      end

      it "should output viable types when run not provided with a type" do
        @mock_fog_interface.stub(:get_execute_query).and_return( 
          { :Link => [
            {:rel=>"down",
             :href=>"query?type=alice&#38;format=references"},
            {:rel=>"down",
             :href=>"query?type=alice&#38;format=records"},
            {:rel=>"down",
             :href=>"query?type=bob&#38;format=records"},
        ]})

        @query.should_receive(:puts).with("alice records,references")
        @query.should_receive(:puts).with("bob   records")

        @query.output_potential_query_types
      end

    end

    context "get results with a single response page" do

      before(:each) do
        @mock_fog_interface = StubFogInterface.new
        Vcloud::FogServiceInterface.stub(:new).and_return(@mock_fog_interface)
        @query = Vcloud::Query.new('bob')
        @mock_fog_interface.stub(:get_execute_query).and_return( { 
          :WibbleRecord=>
            [{:field1=>"Stuff 1",
              :field2=>"Stuff 2",
              :field3=>"Stuff 3",
            },
             {:field1=>"More Stuff 1",
              :field2=>"More Stuff 2",
              :field3=>"More Stuff 3",
            },
            ]
        } )
      end

      it "should output a query in tsv when run with a type" do
        @query = Vcloud::Query.new('bob', :output_format => 'tsv')
        @query.should_receive(:puts).with("field1\tfield2\tfield3")
        @query.should_receive(:puts).with("Stuff 1\tStuff 2\tStuff 3")
        @query.should_receive(:puts).with("More Stuff 1\tMore Stuff 2\tMore Stuff 3")
        @query.run()
      end

      it "should output a query in csv when run with a type" do
        @query = Vcloud::Query.new('bob', :output_format => 'csv')
        @query.should_receive(:puts).with("field1,field2,field3\n")
        @query.should_receive(:puts).with("Stuff 1,Stuff 2,Stuff 3\nMore Stuff 1,More Stuff 2,More Stuff 3\n")
        @query.run()
      end

      it "should output a query in yaml when run with a type"

    end

  end

end

