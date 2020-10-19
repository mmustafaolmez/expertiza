describe StudentTask do
  # Write your mocked object here!
  let(:participant) { build(:participant, id: 1, user_id: user.id, parent_id: assignment.id) }
  let(:participant2) { build(:participant, id: 2, user_id: user2.id, parent_id: assignment.id) }
  let(:participant3) { build(:participant, id: 3, user_id: user3.id, parent_id: assignment2.id) }
  let(:user) { create(:student) }
  let(:user2) { create(:student, name: "qwertyui", id: 5) }
  let(:user3) { create(:student, name: "qwertyui1234", id: 6) }
  let(:course) { build(:course) }
  let(:assignment) { build(:assignment, name: 'assignment 1') }
  let(:assignment2) { create(:assignment, name: 'assignment 2', is_calibrated: true) }
  let(:team) { create(:assignment_team, id: 1, name: 'team 1', parent_id: assignment.id, users: [user, user2]) }
  let(:team2) { create(:assignment_team, id: 2, name: 'team 2', parent_id: assignment2.id, users: [user3]) }
  let(:team_user) { create(:team_user, id: 3, team_id: team.id, user_id: user.id) }
  let(:team_user2) { create(:team_user, id: 4, team_id: team.id, user_id: user2.id) }
  let(:team2_user3) { create(:team_user, id: 5, team_id: team2.id, user_id: user3.id) }
  let(:course_team) { create(:course_team, id: 3, name: 'course team 1', parent_id: course.id) }
  let(:cource_team_user) { create(:team_user, id: 6, team_id: course_team.id, user_id: user.id) }
  let(:cource_team_user2) { create(:team_user, id: 7, team_id: course_team.id, user_id: user2.id) }
  let(:topic) { build(:topic) }
  let(:topic2) { create(:topic, topic_name: "TestReview") }
  let(:due_date) { build(:assignment_due_date, deadline_type_id: 1) }
  let(:deadline_type) { build(:deadline_type, id: 1) }
  let(:review_response_map) { build(:review_response_map, assignment: assignment, reviewer: participant, reviewee: team2) }
  let(:metareview_response_map) { build(:meta_review_response_map, reviewed_object_id: 1) }
  let(:response) { build(:response, id: 1, map_id: 1, response_map: review_response_map) }
  let(:response2) { build(:response, id: 2, map_id: 1, response_map: review_response_map) }
  let(:submission_record) {build(:submission_record, id:1, team_id: 1, assignment_id: 1) }
  let(:student_task) do
    StudentTask.new(
      user: user,
      participant: participant,
      assignment: assignment,
    )
  end


describe "#topic_name" do
	it 'returns the topic name if given one' do
	expect(topic2.topic_name).to eq("TestReview")
	end

end

describe "#complete?" do
      it 'checks a student_task is complete' do
	student_task.stage_deadline = 'Complete'
        expect(student_task.complete?).to be true
      end
end

describe "#incomplete?" do
      it 'checks a student_task is incomplete' do
	expect(student_task.incomplete?).to be true
      end 	
end

  describe "#not_started?" do
    it 'returns true' do
      allow(student_task).to receive(:in_work_stage?).and_return(true)
      allow(student_task).to receive(:started?).and_return(true)
      expect(student_task.not_started?).to eq(false)
    end
  end
  describe "#teamed_students" do
    context 'when not in any team' do
      it 'returns empty' do
        expect(StudentTask.teamed_students(user3)).to eq({})
      end
    end
    context 'when assigned in a cource_team ' do
      it 'returns empty' do
        allow(user).to receive(:teams).and_return([course_team])
        expect(StudentTask.teamed_students(user)).to eq({})
      end
    end
    context 'when assigned in a assignment_team ' do
      it 'returns empty' do
        allow(user).to receive(:teams).and_return([team])
        allow(AssignmentParticipant).to receive(:find_by).with(user_id: 1, parent_id: assignment.id).and_return(participant)
        allow(AssignmentParticipant).to receive(:find_by).with(user_id: 5, parent_id: assignment.id).and_return(participant2)
        allow(Assignment).to receive(:find_by).with(id: team.parent_id).and_return(assignment)
        # allow(Team).to receive(:find).with(team.id).and_return(team)
        expect(StudentTask.teamed_students(user)).to eq({assignment.course_id => [user2.fullname]})
      end
    end
  end
  describe "#get_due_date_data" do
    context 'when called with assignment having empty due dates' do
      it "return empty time_list array" do
        timeline_list = []
        StudentTask.get_due_date_data(assignment, timeline_list)
        expect(timeline_list).to eq([])
      end
    end
    context 'when called with assignment having due date' do
      context 'and due_at value nil' do
        it "return empty time_list array" do
          allow(due_date).to receive(:deadline_type).and_return(deadline_type)
          timeline_list = []
          due_date.due_at=nil;
          assignment.due_dates = [due_date]
          StudentTask.get_due_date_data(assignment, timeline_list)
          expect(timeline_list).to eq([])
        end
      end
      context 'and due_at value not nil' do
        it "return time_list array" do
          allow(due_date).to receive(:deadline_type).and_return(deadline_type)
          timeline_list = []
          assignment.due_dates = [due_date]
          StudentTask.get_due_date_data(assignment, timeline_list)
          expect(timeline_list).to eq([{
                                           :label=>(due_date.deadline_type.name + ' Deadline').humanize,
                                           :updated_at=>due_date.due_at.strftime('%a, %d %b %Y %H:%M')
                                       }])
        end
      end
    end
  end
  describe "#get_peer_review_data" do
    context 'when no review response mapped' do
      it 'returns empty' do
        timeline_list=[]
        StudentTask.get_peer_review_data(user2,timeline_list)
        expect(timeline_list).to eq([])
      end
    end
    context 'when mapped to review response map' do
      it 'returns timeline array' do
        timeline_list=[]
        allow(ReviewResponseMap).to receive_message_chain(:where, :find_each).with(reviewer_id: 1).with(no_args).and_yield(review_response_map)
        allow(review_response_map).to receive(:id).and_return(1)
        allow(Response).to receive_message_chain(:where, :last).with(map_id: 1).with(no_args).and_return(response)
        allow(response).to receive(:round).and_return(1)
        allow(response).to receive(:updated_at).and_return(Time.new(2019))
        timevalue = Time.new(2019).strftime('%a, %d %b %Y %H:%M')
        expect(StudentTask.get_peer_review_data(1,timeline_list)).to eq([{:id=>1, :label=>"Round 1 peer review", :updated_at=>timevalue}])
      end
    end
  end
  describe "#get_author_feedback_data" do
    context 'when no feedback response mapped' do
      it 'returns empty' do
        timeline_list=[]
        StudentTask.get_author_feedback_data(user2,timeline_list)
        expect(timeline_list).to eq([])
      end
    end
    context 'when mapped to feedback response map' do
      it 'returns timeline array' do
        timeline_list=[]
        allow(FeedbackResponseMap).to receive_message_chain(:where, :find_each).with(reviewer_id: 1).with(no_args).and_yield(review_response_map)
        allow(review_response_map).to receive(:id).and_return(1)
        allow(Response).to receive_message_chain(:where, :last).with(map_id: 1).with(no_args).and_return(response)
        allow(response).to receive(:updated_at).and_return(Time.now)
        timevalue = Time.now.strftime('%a, %d %b %Y %H:%M')
        expect(StudentTask.get_author_feedback_data(1,timeline_list)).to eq([{:id=>1, :label=>"Author feedback", :updated_at=>timevalue}])
      end
    end
  end
  describe '#get_submission_data' do
    context 'when no submission data mapped' do
      it 'returns nil' do
        timeline_list=[]
        expect(StudentTask.get_submission_data(1,1,timeline_list)).to eq(nil)
      end
    end
    context 'when submission data mapped and not submit hyperlink or Remove hyperlink' do
      it 'returns timeline_list' do
        timeline_list=[]
        allow(SubmissionRecord).to receive_message_chain(:where, :find_each).with(team_id: 1, assignment_id: 1).with(no_args).and_yield(submission_record)
        allow(submission_record).to receive(:operation).and_return('testing_label')
        allow(submission_record).to receive(:updated_at).and_return(Time.new(2019))
        timevalue = Time.new(2019).strftime('%a, %d %b %Y %H:%M')
        expect(StudentTask.get_submission_data(1,1,timeline_list)).to eq([{:label=>"Testing label", :updated_at=>timevalue}])
      end
    end
    context 'when submission data mapped and operation is submit_hyperlink' do
      it 'returns timeline_list with link' do
        timeline_list=[]
        allow(SubmissionRecord).to receive_message_chain(:where, :find_each).with(team_id: 1, assignment_id: 1).with(no_args).and_yield(submission_record)
        allow(submission_record).to receive(:operation).and_return('Submit Hyperlink')
        allow(submission_record).to receive(:updated_at).and_return(Time.new(2019))
        timevalue = Time.new(2019).strftime('%a, %d %b %Y %H:%M')
        expect(StudentTask.get_submission_data(1,1,timeline_list)).to eq([{:label=>"Submit hyperlink", :updated_at=>timevalue, :link=>"www.wolfware.edu"}])
      end
    end
    context 'when submission data mapped and operation is Remove Hyperlink' do
      it 'returns timeline_list with link' do
        timeline_list=[]
        allow(SubmissionRecord).to receive_message_chain(:where, :find_each).with(team_id: 1, assignment_id: 1).with(no_args).and_yield(submission_record)
        allow(submission_record).to receive(:operation).and_return('Remove Hyperlink')
        timevalue = Time.new(2019).strftime('%a, %d %b %Y %H:%M')
        allow(submission_record).to receive(:updated_at).and_return(Time.new(2019))
        expect(StudentTask.get_submission_data(1,1,timeline_list)).to eq([{:label=>"Remove hyperlink", :updated_at=>timevalue, :link=>"www.wolfware.edu"}])
      end
    end
  end

describe "#revision?" do
	it 'returns true if content is submitted' do
	allow(student_task).to receive(:content_submitted_in_current_stage?).and_return(true)
	allow(student_task).to receive(:reviews_given_in_current_stage?).and_return(false)
	allow(student_task).to receive(:metareviews_given_in_current_stage?).and_return(false)
	expect(student_task.revision?).to eq(true)
	end

	it 'returns true if reviews given is true' do
	allow(student_task).to receive(:content_submitted_in_current_stage?).and_return(false)
	allow(student_task).to receive(:reviews_given_in_current_stage?).and_return(true)
	allow(student_task).to receive(:metareviews_given_in_current_stage?).and_return(false)
	expect(student_task.revision?).to eq(true)
	end

	it 'returns true if metareviews given is true' do
	allow(student_task).to receive(:content_submitted_in_current_stage?).and_return(false)
	allow(student_task).to receive(:reviews_given_in_current_stage?).and_return(false)
	allow(student_task).to receive(:metareviews_given_in_current_stage?).and_return(true)
	expect(student_task.revision?).to eq(true)
	end
	
end

describe "#metreviews_given_in_current_stage?" do
	it 'return true' do
	student_task.current_stage = "metareview"
	allow(student_task).to receive(:metareviews_given?).and_return(true)
	expect(student_task.metareviews_given_in_current_stage?).to eq(true)
	end
end

describe "#reviews_given_in_current_stage?" do
	it 'return true' do
	student_task.current_stage = "review"
	allow(student_task).to receive(:reviews_given?).and_return(true)
	expect(student_task.reviews_given_in_current_stage?).to eq(true)
	end
end


end
