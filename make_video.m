function make_video(filename, clips)
    padding = 0.5;      % Padding on both sides of each clip
    frame_dur = 1;      % Round up durations of each clip to multiples of this
    video_fs = 44100;   % All audio signals are converted to this fs
    writer = vision.VideoFileWriter(filename, ...
        'FileFormat', 'AVI', ...
        'FrameRate', 1 / frame_dur, ...
        'AudioInputPort', true, ...
        'VideoCompressor', 'MJPEG Compressor' ...
    );

    set(gcf, 'Position', [0 0 800 600]);
    for i = 1:length(clips)
        clip = clips(i);
        x = clip.signal;
        fs = clip.fs;

        clf;
        if size(x, 2) == 1      % Mono
            [s, f, tt] = spectrogram(x, fs * 0.02, [], [], fs);
            imagesc(tt, f, log(abs(s)), [-10, 3.25]);
            colormap(jet);
            set(gca, 'YDir', 'normal');
            p = get(gca, 'Position');
            p(4) = clip.fs / 16000 * 0.7;
            set(gca, 'Position', p);
            xlabel('Time / s'); ylabel('Frequency / Hz');
            title(clip.title);
        else                    % Stereo
            channels = {'left', 'right'};
            for ch = 1:2
                subplot(2, 1, ch);
                [s, f, tt] = spectrogram(x(:, ch), fs * 0.02, [], [], fs);
                imagesc(tt, f, log(abs(s)), [-10, 3.25]);
                colormap(jet);
                set(gca, 'YDir', 'normal');
                p = get(gca, 'Position');
                p(4) = clip.fs / 16000 * 0.7;
                set(gca, 'Position', p);
                xlabel('Time / s'); ylabel('Frequency / Hz');
                title([clip.title, ' (', channels{ch}, ' channel)']);
            end
        end
        img = getframe(gcf);
        
        n_frames = ceil((length(x) / fs + padding * 2) / frame_dur);
        audio_track = zeros(n_frames * frame_dur * video_fs, size(x, 2));
        y = resample(x, video_fs, fs);
        audio_track(padding * video_fs + (1 : length(y)), :) = y;
        audio_offset = 0;
        for j = 1:n_frames
            audio_frame = audio_track(audio_offset + (1 : video_fs * frame_dur), :);
            if size(audio_frame, 2) == 1
                audio_frame = [audio_frame, audio_frame];   % Mono to stereo
            end
            step(writer, img.cdata, audio_frame);
            audio_offset = audio_offset + video_fs * frame_dur;
        end
    end

    release(writer);
end
