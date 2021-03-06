require_relative '../task_queue'

module TaskQueue
  describe TaskQueue do
    def wait_for_task_to_complete(task: nil)
      sleep 0.0001 until task.completed
    end

    it 'Executes one block of work with just 1 worker' do
      queue = TaskQueue.new(name: 'test queue')
      work_completed = false
      task = Task.new(work_block: proc { work_completed = true })
      queue.add_task_async(task: task)
      wait_for_task_to_complete(task: task)
      expect(work_completed).to be(true)
    end

    it 'Executes ensure block' do
      queue = TaskQueue.new(name: 'test queue')
      work_completed = false
      ensured = false
      task = Task.new(work_block: proc { work_completed = true }, ensure_block: proc { ensured = true })
      queue.add_task_async(task: task)
      wait_for_task_to_complete(task: task)
      expect(work_completed).to be(true)
      expect(ensured).to be(true)
    end

    it 'Executes ensure block on exception' do
      ensured = false
      expect {
        queue = TaskQueue.new(name: 'test queue')
        task = Task.new(work_block: proc { raise "Oh noes" }, ensure_block: proc { ensured = true })
        queue.add_task_async(task: task)
        wait_for_task_to_complete(task: task)
      }.to raise_error

      expect(ensured).to be(true)
    end

    it 'Executes 2 blocks of work with just 1 worker' do
      queue = TaskQueue.new(name: 'test queue')

      work_completed1 = false
      work_completed2 = false

      task1 = Task.new(work_block: proc do work_completed1 = true end)
      task2 = Task.new(work_block: proc do work_completed2 = true end)
      queue.add_task_async(task: task1)
      queue.add_task_async(task: task2)

      wait_for_task_to_complete(task: task1)
      wait_for_task_to_complete(task: task2)

      expect(work_completed1).to be(true)
      expect(work_completed2).to be(true)
    end

    it 'Executes 2 blocks of work with 2 workers' do
      queue = TaskQueue.new(name: 'test queue', number_of_workers: 2)

      work_completed1 = false
      work_completed2 = false

      task1 = Task.new(work_block: proc do work_completed1 = true end)
      task2 = Task.new(work_block: proc do work_completed2 = true end)
      queue.add_task_async(task: task1)
      queue.add_task_async(task: task2)

      wait_for_task_to_complete(task: task1)
      wait_for_task_to_complete(task: task2)

      expect(work_completed1).to be(true)
      expect(work_completed2).to be(true)
    end

    it 'Executes 1000 blocks of work with 1 worker, in serial' do
      queue = TaskQueue.new(name: 'test queue')

      numbers = []
      expected_results = []
      # count from 0 to 9999
      1000.times { |i| expected_results << i }

      tasks = expected_results.map do |number|
        # Task that when executed appends the current number to the `numbers` array
        # This should be done in sequence
        Task.new(work_block: proc do numbers << number end)
      end

      tasks.each { |task| queue.add_task_async(task: task) }
      tasks.each { |task| wait_for_task_to_complete(task: task) }

      # expect count from 0 to 9999 for both arrays since we're in serial mode
      expect(numbers).to eq(expected_results)
    end

    it 'Executes 1000 blocks of work with 10 workers' do
      queue = TaskQueue.new(name: 'test queue', number_of_workers: 10)

      numbers = []
      expected_results = []
      # count from 0 to 9999
      1000.times { |i| expected_results << i }

      tasks = expected_results.map do |number|
        Task.new(work_block: proc do numbers << number end)
      end

      tasks.each { |task| queue.add_task_async(task: task) }
      tasks.each { |task| wait_for_task_to_complete(task: task) }
    end

    it 'Executes 50 blocks of work with 2 workers' do
      queue = TaskQueue.new(name: 'test queue', number_of_workers: 3)

      numbers = []
      expected_results = []
      # count from 0 to 50
      50.times { |i| expected_results << i }

      tasks = expected_results.map do |number|
        Task.new(work_block: proc do numbers << number end)
      end

      tasks.each { |task| queue.add_task_async(task: task) }
      tasks.each { |task| wait_for_task_to_complete(task: task) }

      # expect that the arrays aren't equal because this was async
      expect(numbers).to_not eq(expected_results)
    end
  end
end
