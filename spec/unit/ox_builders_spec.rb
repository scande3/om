require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "OpinionatedXml" do
  
  before(:all) do
    #ModsHelpers.name_("Beethoven, Ludwig van", :date=>"1770-1827", :role=>"creator")
    class FakeOxMods < Nokogiri::XML::Document
      
      include OX
      extend OX::ClassMethods
      
      
      # Could add support for multiple root declarations.  
      #  For now, assume that any modsCollections have already been broken up and fed in as individual mods documents
      # root :mods_collection, :path=>"modsCollection", 
      #           :attributes=>[],
      #           :subelements => :mods
                     
      root_property :mods, "mods", "http://www.loc.gov/mods/v3", :attributes=>["id", "version"], :schema=>"http://www.loc.gov/standards/mods/v3/mods-3-2.xsd"          
                
                
      property :name_, :path=>"name", 
                  :attributes=>[:xlink, :lang, "xml:lang", :script, :transliteration, {:type=>["personal", "enumerated", "corporate"]} ],
                  :subelements=>["namePart", "displayForm", "affiliation", :role, "description"],
                  :default_content_path => "namePart",
                  :convenience_methods => {
                    :date => {:path=>"namePart", :attributes=>{:type=>"date"}},
                    :family_name => {:path=>"namePart", :attributes=>{:type=>"family"}},
                    :given_name => {:path=>"namePart", :attributes=>{:type=>"given"}},
                    :terms_of_address => {:path=>"namePart", :attributes=>{:type=>"termsOfAddress"}}
                  }
                  
      property :person, :variant_of=>:name_, :attributes=>{:type=>"personal"}
      
      property :role, :path=>"role",
                  :parents=>[:name_],
                  :attributes=>[ { "type"=>["text", "code"] } , "authority"],
                  :default_content_path => "roleTerm"
                  
                  
    end
  end
  
  after(:all) do
    Object.send(:remove_const, :FakeOxMods)
  end
    
  describe "generated builder methods" do
    describe "#name" do
      it "should construct name nodes" do
        n1 = FakeOxMods.name_("Beethoven, Ludwig van", :date=>"1770-1827")
        n1.to_xml.should == Nokogiri::XML.parse('
        <name type="personal">
          <namePart>Beethoven, Ludwig van</namePart>
          <namePart type="date">1770-1827</namePart>
        </name>').to_xml
    
        n2 = FakeOxMods.name_("Naxos Digital Services", :type=>"corporate")
        n2.to_xml.should == Nokogiri::XML.parse('<name type="corporate"><namePart>Naxos Digital Services</namePart></name>').to_xml
    
        n3 = FakeOxMods.name_("Alterman, Eric", :role=>"creator")
        n3.to_xml.should == Nokogiri::XML.parse('<name type="personal"><namePart>Alterman, Eric</namePart><role><roleTerm type="text">creator</roleTerm></role></name>').to_xml
    
        n4 = FakeOxMods.person("Tuell, Hiram.", :role=>{:value=>"creator", :authority=>"marcrelator"})
        n4.to_xml.should == Nokogiri::XML.parse('
        <name type="personal"><namePart>Tuell, Hiram.</namePart>
          <role>
            <roleTerm type="text" authority="marcrelator">creator</roleTerm>
          </role>
        </name>').to_xml
      end
    end
  
    describe '#role' do
      it "should construct role nodes" do
        r1 = FakeOxMods.role("creator")
        r1.to_xml.should == Nokogiri::XML.parse('<role><roleTerm type="text">creator</roleTerm></role>').to_xml
    
        r2 = FakeOxMods.role("creator", :authority=>"marcrelator")
        r2.to_xml.should == Nokogiri::XML.parse('<role><roleTerm type="text" authority="marcrelator">creator</roleTerm></role>').to_xml
      end
      it "should accept a root node to insert its results into" do
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.foo {
            xml.bar {
              FakeOxMods.role("creator", {:authority=>"marcrelator"}, xml.parent)
            }
          }
        end
        builder.to_xml.should == Nokogiri::XML.parse('<foo><bar><role><roleTerm type="text" authority="marcrelator">creator</roleTerm></role></bar></foo>').to_xml
      
      end
    end
  end
end