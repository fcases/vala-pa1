using Gtk;
using PortAudio;
using KissFFT;
//  [CCode (cheader_filename = "string.h")]
//  extern void* memcpy (void* dest, void* src, size_t n);

void device_info_free(DeviceInfo di_ref){
//    free(di_ref);
}

void stream_parameters_free(Stream.Parameters sp_ref) {
    //free(sp_ref);
}


namespace myPA {
    //////////////////////////////////////
    //  class SyncObj
    //////////////////////////////////////
    class SyncObj {
        Mutex theMutex;
    
        public bool Block()  {
            return theMutex.trylock();
        }
    
        public void Unblock() {
            theMutex.unlock();
        }
    
        public void Reset() {
            if (theMutex.trylock()) theMutex.unlock();
        }
    }
    
    //////////////////////////////////////
    //  class myIfcPA
    //////////////////////////////////////
    public class myIfcPA{ 
        const ulong SAMPLES = 1024;
        const ulong FRAMERATE = 44100;

        public PortAudio.Error err= ErrorCode.NO_ERROR;
        SyncObj theSync=new SyncObj();
        DeviceIndex numDevices;
        List<DeviceInfo> deviceInfoList = new List<DeviceInfo>();
        Stream.Parameters inSP;
        Stream.Parameters outSP;
        Stream miStream;
        public float[] RawAudio=new float[SAMPLES];
        public float[] ModAudio=new float[SAMPLES];

        Cfg miCfg;
        Cpx [] misDatosIn =new Cpx[SAMPLES];
        Cpx [] misDatosOut =new Cpx[SAMPLES];

        static uint many=0;
        double time=0;
        Timer t1;
        static Timer t2=new Timer();
        ulong microseconds;
        
        public myIfcPA() {
            err =initialize();
            if( err == ErrorCode.NO_ERROR) FillInfo();

            t1=new Timer();
        }

        void FillInfo() {
            numDevices = get_device_count();
    
            for(int i = 0; i < numDevices; i++) {
                var aux = new DeviceInfo(i);
                stdout.printf("Info for Device %d: %s - %d - %d\n", i, aux.name, aux.max_input_channels, aux.max_output_channels ) ;
                deviceInfoList.append((owned)aux);
            }
    
            inSP.channel_count = 1;
            inSP.sample_format = FLOAT_32;
            inSP.suggested_latency = 0.0;
            outSP.channel_count = 1;
            outSP.sample_format = FLOAT_32;
            outSP.suggested_latency = 0.0;

            miCfg=alloc((int)SAMPLES,false,null,null);
        }
    
        void Terminate() {
            terminate();
            if( err != ErrorCode.NO_ERROR ) {
                stdout.printf("Error %d! %s\n", err, get_error_text(err) );
            }
            deviceInfoList.foreach ((entry) => {
                deviceInfoList.remove(entry);
            });
        }
        
        public void Start() {
            theSync.Reset();
            Stream.open(out miStream,inSP, outSP, FRAMERATE, SAMPLES, Stream.NO_FLAG, FuzzCallback);
            miStream.start();

            t1.start();
        }
    
        public void Stop() {
            miStream.stop();
            miStream.close();
            theSync.Reset();

            t1.stop();
            double seconds;

            seconds = t1.elapsed (out microseconds);
            print ("PA: Total segundos: %s\n", seconds.to_string ());
            print ("PA: milisec por vez: %f\n", seconds*1000/many);
            print ("PA: %5.0f veces, %f veces/s \n", many, many/seconds);
            print ("PA: cb total time en ms  %f, usec por vez %f\n\n",time*1000,time*1000000/many);
            many=0;
            time=0;
        }
    
        public bool CheckCompatibility(DeviceIndex x, DeviceIndex y) {
            inSP.device = x;
            outSP.device = y;
            var devI=new DeviceInfo(x);
            inSP.suggested_latency = devI.default_low_input_latency;
            var devO=new DeviceInfo(y);
            outSP.suggested_latency = devO.default_low_input_latency;
            if(is_format_supported(inSP, outSP, FRAMERATE) != ErrorCode.NO_ERROR)
                return false;
            else
                return true;
        }    

        public unowned List<DeviceInfo> GetDevices()  {
            return deviceInfoList;
        }
    
        public bool GetInputdata(float[] dataRaw, float[] dataMod) {
            if( theSync.Block() ) {
                Memory.copy(dataRaw,RawAudio,SAMPLES*sizeof(float));
                Memory.copy(dataMod,ModAudio,SAMPLES*sizeof(float));
                theSync.Unblock();
                return true;
            }
    
            return false;
        }

        int FuzzCallback(void* inputBuffer, void* outputBuffer,ulong frame_count,Stream.CallbackTimeInfo time_info,Stream.CallbackFlags status_flags) {
            t2.start();

            var ptrIn= (float*) inputBuffer;
            var ptrOut=(float*) outputBuffer;
            var Amp=2.2f;
            for(int i=0;i<SAMPLES;i++) {
                misDatosIn[i].r=  ptrIn[i];
                ptrOut[i] = ptrIn[i]*Amp;
                misDatosIn[i].i=0.0f;
            }
            transform(miCfg,misDatosIn,misDatosOut);
  
            var K2=0.25f;
            float[] mod=new float[SAMPLES];
            for(int i=0;i<SAMPLES;i++) {
                mod[i]=misDatosOut[i].r*misDatosOut[i].r+misDatosOut[i].i*misDatosOut[i].i;
                mod[i]=(float)Math.sqrt(mod[i])*K2;
            }
            
            if(  theSync.Block() ) {
                //  Memory.copy(RawAudio,ptrIn,1024*sizeof(float));
                Memory.copy(RawAudio,ptrOut,1024*sizeof(float));
                Memory.copy(ModAudio,mod,1024*sizeof(float));
                theSync.Unblock();
            }
    
            t2.stop();
            time+=t2.elapsed(out microseconds);
            many++;
            return 0;
        }
    
    }
}

/*
const fft = @import("fft.zig");

pub const PA = struct {

    fn c_FuzzCallback(inputBuffer: ?*const anyopaque, outputBuffer: ?*anyopaque, _: c_ulong, _: [*c]const c.PaStreamCallbackTimeInfo, _: c.PaStreamCallbackFlags, ptr: ?*anyopaque) callconv(.C) c_int {
        const ptrIn: *[SAMPLES]f32 = @constCast(@ptrCast(@alignCast(inputBuffer)));
        const ptrOut: *[SAMPLES]f32 = @constCast(@ptrCast(@alignCast(outputBuffer)));

        const in: [SAMPLES]f32 = ptrIn.*;
        var vAmp: @Vector(SAMPLES, f32) = ptrIn.*;

        const K: @Vector(SAMPLES, f32) = @splat(2.2);
        vAmp = K * vAmp;

        var out: [SAMPLES]f32 = vAmp;
        @memcpy(ptrOut, &out);

        var zeros: [SAMPLES]f32 = .{0.0} ** SAMPLES;
        _ = fft.fft(f32, @constCast(&in), &zeros) catch 0;
        const real: @Vector(SAMPLES, f32) = in;
        const imag: @Vector(SAMPLES, f32) = zeros;

        const K2: @Vector(SAMPLES, f32) = @splat(0.05);
        const mod = @sqrt(real * real + imag * imag) * K2;
        out = mod;
        //const arg=imag/real;

        var self: *PA = @ptrCast(@alignCast(ptr));
        if (self.theSync.Block()) {
            @memcpy(&self.RawAudio, &ptrIn.*);
            @memcpy(&self.ModAudio, &out);
            self.theSync.Unblock();
        }

        return 0;
    }

};
*/