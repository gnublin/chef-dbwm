# MIT License
# Copyright (c) 2018 Gauthier FRANCOIS

# require 'spec_helper'
# require 'models/event'
# require 'time'
# require 'json'

# describe Event do
#   before do
#     data = JSON.parse(IO.read('sample.json'))
#     allow(Event).to receive(:fetch_events).and_return(data)
#   end

#   describe '#initialize' do
#     subject { Event.all.first }

#     it('sets status') { expect(subject.status).to eql 1 }
#     it('sets muted') { expect(subject.muted).to be false }
#     it('sets host') { expect(subject.host).to eql 'lb00-test' }
#     it('sets retries') { expect(subject.retries).to eql 142_434 }
#     it('sets last_ok') { expect(subject.last_ok).to eql Time.parse('2017-06-26 15:33:33 +0200') }
#     it('sets last_failure') { expect(subject.last_failure).to eql Time.parse('2017-10-03 13:31:32 +0200') }
#     it('sets name') { expect(subject.name).to eql 'service-filebeat' }
#   end
# end
