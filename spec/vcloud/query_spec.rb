require 'spec_helper'

describe Vcloud::Query do
  context "attributes" do
    before(:all) do
      @mock_fog_interface = StubFogInterface.new
      Vcloud::FogServiceInterface.stub(:new).and_return(@mock_fog_interface)
      @query = Vcloud::Query.new
    end

    it { @query.should respond_to(:run) }

    context "run" do
      it "should call get_and_output_potential_query_types when run not provided with a type" do
        @query.should_receive(:get_and_output_potential_query_types)
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

        @query.get_and_output_potential_query_types
      end

      it "should output a query in tsv when run with a type" do
        @query.should_receive(:get_and_output_query_results).with('bob')
        @query.run('bob')
      end

      it "should output yaml when run with a type and yaml output option"

      it "should output csv when run with a type and csv output option" 

      it "should output tsv when run with a type and tsv output option" 

    end

  end

end

